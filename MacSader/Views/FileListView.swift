import SwiftUI

struct FileListView: View {
    @ObservedObject var viewModel: PanelViewModel
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let fileOps: FileOperationViewModel
    let otherPanelPath: String

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            ColumnHeaderView(viewModel: viewModel)

            // File list
            ScrollViewReader { proxy in
                List(selection: Binding(
                    get: { viewModel.cursorItem },
                    set: { viewModel.cursorItem = $0 }
                )) {
                    // Parent directory entry
                    if viewModel.currentPath != "/" {
                        FileRowView(
                            item: FileItem.parentDirectory(for: viewModel.currentPath),
                            isSelected: false,
                            isCursor: false,
                            showIcons: appState.showIconsInFileList,
                            columnConfig: appState.columnConfig,
                            fontSize: appState.fontSize
                        )
                        .tag("..")
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        .listRowBackground(Color.clear)
                        .onTapGesture(count: 2) {
                            Task { await viewModel.goUp() }
                        }
                        .onTapGesture {
                            viewModel.cursorItem = ".."
                        }
                    }

                    ForEach(viewModel.filteredItems) { item in
                        FileRowView(
                            item: item,
                            isSelected: viewModel.selectedItems.contains(item.id),
                            isCursor: viewModel.cursorItem == item.id,
                            showIcons: appState.showIconsInFileList,
                            columnConfig: appState.columnConfig,
                            fontSize: appState.fontSize
                        )
                        .tag(item.id)
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        .listRowBackground(rowBackground(for: item))
                        .onTapGesture(count: 2) {
                            Task { await viewModel.enterDirectory(item) }
                        }
                        .onTapGesture {
                            if NSEvent.modifierFlags.contains(.command) {
                                viewModel.toggleSelection(item.id)
                            }
                            viewModel.cursorItem = item.id
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: viewModel.cursorItem) { _, newValue in
                    if let id = newValue {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func rowBackground(for item: FileItem) -> some View {
        Group {
            if viewModel.selectedItems.contains(item.id) && viewModel.cursorItem == item.id {
                AppTheme.rowSelectedBackground
            } else if viewModel.selectedItems.contains(item.id) {
                AppTheme.rowSelectedBackground.opacity(0.7)
            } else if viewModel.cursorItem == item.id {
                AppTheme.rowCursorBackground
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Column Header
struct ColumnHeaderView: View {
    @ObservedObject var viewModel: PanelViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Name column
            columnHeader("Name", field: .name)
                .frame(minWidth: 100, maxWidth: .infinity)

            if appState.columnConfig.showExtension {
                columnHeader("Ext", field: .ext)
                    .frame(width: appState.columnConfig.extWidth)
            }

            if appState.columnConfig.showSize {
                columnHeader("Size", field: .size)
                    .frame(width: appState.columnConfig.sizeWidth)
            }

            if appState.columnConfig.showDate {
                columnHeader("Date", field: .date)
                    .frame(width: appState.columnConfig.dateWidth)
            }

            if appState.columnConfig.showPermissions {
                Text("Perms")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: appState.columnConfig.permissionsWidth)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
    }

    private func columnHeader(_ title: String, field: SortField) -> some View {
        Button {
            viewModel.toggleSort(field)
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                if viewModel.sortField == field {
                    Image(systemName: viewModel.sortOrder == .ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
