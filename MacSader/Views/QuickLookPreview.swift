import SwiftUI
import QuickLookUI

struct QuickLookPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = true
        view.previewItem = url as QLPreviewItem
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as QLPreviewItem
    }
}

struct PreviewPanel: View {
    let item: FileItem?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "eye")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Preview")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if let item = item {
                if item.isDirectory {
                    directoryPreview(item)
                } else {
                    QuickLookPreview(url: URL(fileURLWithPath: item.path))
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No selection")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                    Spacer()
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func directoryPreview(_ item: FileItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium))
                    Text(item.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()

            Divider()

            if let count = directoryItemCount(item.path) {
                Label("\(count) items", systemImage: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Label(item.displayDate, systemImage: "calendar")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Label(item.permissions, systemImage: "lock.shield")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
    }

    private func directoryItemCount(_ path: String) -> Int? {
        try? FileManager.default.contentsOfDirectory(atPath: path).count
    }
}
