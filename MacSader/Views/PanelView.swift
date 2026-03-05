import SwiftUI

struct PanelView: View {
    @ObservedObject var viewModel: PanelViewModel
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let fileOps: FileOperationViewModel
    let otherPanelPath: String

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            TabBarView(viewModel: viewModel, isActive: isActive)

            // Path bar
            PathBarView(viewModel: viewModel, isActive: isActive)

            // Quick search bar (conditional)
            if viewModel.isQuickSearchActive {
                QuickSearchBar(viewModel: viewModel)
            }

            // File list
            FileListView(
                viewModel: viewModel,
                isActive: isActive,
                fileOps: fileOps,
                otherPanelPath: otherPanelPath
            )

            // Status bar
            StatusBar(viewModel: viewModel)
        }
        .background(AppTheme.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    isActive ? AppTheme.panelActiveAccent : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Quick Search Bar
struct QuickSearchBar: View {
    @ObservedObject var viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 11))

            TextField("Filter...", text: $viewModel.quickSearchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .onChange(of: viewModel.quickSearchText) { _, _ in
                    viewModel.applyQuickSearch()
                }

            if !viewModel.quickSearchText.isEmpty {
                Text("\(viewModel.filteredItems.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)

                Button {
                    viewModel.quickSearchText = ""
                    viewModel.applyQuickSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @ObservedObject var viewModel: PanelViewModel

    var body: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            }

            Text("\(viewModel.filteredItems.count) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if !viewModel.selectedItems.isEmpty {
                Text("| \(viewModel.selectedItems.count) selected")
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)

                let totalSize = viewModel.filteredItems
                    .filter { viewModel.selectedItems.contains($0.id) }
                    .reduce(Int64(0)) { $0 + $1.size }
                if totalSize > 0 {
                    Text("(\(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let error = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 10))
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }
}
