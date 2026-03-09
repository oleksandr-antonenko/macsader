import SwiftUI

struct VolumeInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let path: String
    let icon: NSImage
    let totalSize: Int64
    let freeSize: Int64
    let isRemovable: Bool
    let isNetwork: Bool
    let isInternal: Bool

    var freeSpaceText: String {
        let free = ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        return "\(free) of \(total)"
    }

    var shortFreeText: String {
        ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file)
    }
}

struct VolumeSelectorView: View {
    @ObservedObject var viewModel: PanelViewModel
    @State private var volumes: [VolumeInfo] = []
    @State private var isExpanded = false

    var currentVolume: VolumeInfo? {
        let path = viewModel.currentPath
        // Find the volume whose path is the longest prefix of the current path
        return volumes
            .filter { path.hasPrefix($0.path) }
            .max(by: { $0.path.count < $1.path.count })
    }

    var body: some View {
        HStack(spacing: 0) {
            // Volume dropdown
            Menu {
                ForEach(volumes) { volume in
                    Button {
                        Task { await viewModel.navigate(to: volume.path) }
                    } label: {
                        HStack {
                            Image(nsImage: volume.icon)
                            Text(volume.name)
                            Spacer()
                            Text(volume.shortFreeText)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let vol = currentVolume {
                        Image(nsImage: vol.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text(vol.name)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary)

                        Divider()
                            .frame(height: 12)
                            .padding(.horizontal, 2)

                        Text(vol.shortFreeText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                    } else {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 11))
                        Text("Volumes")
                            .font(.system(size: 11))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .onAppear { refreshVolumes() }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didMountNotification)) { _ in
            refreshVolumes()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didUnmountNotification)) { _ in
            refreshVolumes()
        }
    }

    private func refreshVolumes() {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey,
            .effectiveIconKey,
            .volumeIsLocalKey
        ]

        guard let volumeURLs = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return }

        var result: [VolumeInfo] = []
        for url in volumeURLs {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let name = values.volumeName ?? url.lastPathComponent
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = Int64(values.volumeAvailableCapacity ?? 0)
            let isRemovable = values.volumeIsRemovable ?? false
            let isInternal = values.volumeIsInternal ?? true
            let isLocal = values.volumeIsLocal ?? true
            let icon = (values.effectiveIcon as? NSImage) ?? NSImage(systemSymbolName: "externaldrive", accessibilityDescription: nil)!

            // Resize icon
            let smallIcon = NSImage(size: NSSize(width: 16, height: 16))
            smallIcon.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
            smallIcon.unlockFocus()

            result.append(VolumeInfo(
                id: url.path,
                name: name,
                path: url.path,
                icon: smallIcon,
                totalSize: total,
                freeSize: free,
                isRemovable: isRemovable,
                isNetwork: !isLocal,
                isInternal: isInternal
            ))
        }

        // Sort: internal first, then external, then network
        result.sort { a, b in
            if a.isInternal != b.isInternal { return a.isInternal }
            if a.isNetwork != b.isNetwork { return !a.isNetwork }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }

        volumes = result
    }
}
