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

            // Quick search bar
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
            StatusBar(viewModel: viewModel, isActive: isActive)
        }
        .background(AppTheme.panelBackground)
        .overlay(alignment: .top) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
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
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)

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
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            }

            // Item count
            Image(systemName: "doc.on.doc")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
            Text("\(viewModel.filteredItems.count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)

            if !viewModel.selectedItems.isEmpty {
                Divider().frame(height: 12)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.accentColor)
                Text("\(viewModel.selectedItems.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.accentColor)

                let totalSize = viewModel.filteredItems
                    .filter { viewModel.selectedItems.contains($0.id) }
                    .reduce(Int64(0)) { $0 + $1.size }
                if totalSize > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let error = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 10))
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            isActive
                ? Color.accentColor.opacity(0.06)
                : Color(nsColor: .windowBackgroundColor).opacity(0.8)
        )
    }
}
