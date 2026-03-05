import SwiftUI

struct PathBarView: View {
    @ObservedObject var viewModel: PanelViewModel
    let isActive: Bool

    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 2) {
            // Back / Forward buttons
            Button {
                Task { await viewModel.goBack() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.historyIndex <= 0)
            .foregroundColor(viewModel.historyIndex > 0 ? .secondary : .secondary.opacity(0.3))
            .help("Back (Cmd+[)")

            Button {
                Task { await viewModel.goForward() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.historyIndex >= viewModel.history.count - 1)
            .foregroundColor(viewModel.historyIndex < viewModel.history.count - 1 ? .secondary : .secondary.opacity(0.3))
            .help("Forward (Cmd+])")

            Button {
                Task { await viewModel.goUp() }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Go Up")

            Divider()
                .frame(height: 14)
                .padding(.horizontal, 2)

            if isEditing {
                TextField("Path", text: $editText, onCommit: {
                    let path = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !path.isEmpty {
                        Task { await viewModel.navigate(to: (path as NSString).expandingTildeInPath) }
                    }
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .onExitCommand { isEditing = false }
            } else {
                // Breadcrumb path
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 1) {
                        ForEach(Array(viewModel.pathComponents.enumerated()), id: \.offset) { index, component in
                            if index > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }

                            Button {
                                Task { await viewModel.navigate(to: component.path) }
                            } label: {
                                Text(component.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(
                                        index == viewModel.pathComponents.count - 1
                                            ? .primary
                                            : .secondary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onTapGesture(count: 2) {
                    editText = viewModel.currentPath
                    isEditing = true
                }
            }

            Spacer()

            // Disk free space (for local paths)
            if !viewModel.currentPath.contains("://") {
                if let freeSpace = diskFreeSpace(for: viewModel.currentPath) {
                    Text(freeSpace)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: AppTheme.pathBarHeight)
        .background(AppTheme.pathBarBackground.opacity(0.5))
    }

    private func diskFreeSpace(for path: String) -> String? {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let freeBytes = attrs[.systemFreeSize] as? Int64 else { return nil }
        return ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file) + " free"
    }
}
