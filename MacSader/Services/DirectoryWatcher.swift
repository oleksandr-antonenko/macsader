import Foundation

class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let path: String
    private let callback: () -> Void
    private var debounceWorkItem: DispatchWorkItem?

    init(path: String, callback: @escaping () -> Void) {
        self.path = path
        self.callback = callback
    }

    func start() {
        stop()

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: .global(qos: .utility)
        )

        source?.setEventHandler { [weak self] in
            self?.debounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.callback()
            }
            self?.debounceWorkItem = work
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3, execute: work)
        }

        source?.setCancelHandler {
            close(fd)
        }

        source?.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    deinit {
        stop()
    }
}
