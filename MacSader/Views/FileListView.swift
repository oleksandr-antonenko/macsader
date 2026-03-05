import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @ObservedObject var viewModel: PanelViewModel
    @EnvironmentObject var appState: AppState
    let isActive: Bool
    let fileOps: FileOperationViewModel
    let otherPanelPath: String

    @State private var dropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            ColumnHeaderView(viewModel: viewModel)

            ScrollViewReader { proxy in
                List(selection: Binding(
                    get: { viewModel.cursorItem },
                    set: { viewModel.cursorItem = $0 }
                )) {
                    // Parent directory entry
                    if viewModel.currentPath != "/" {
                        parentRow
                    }

                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                        fileRow(item: item, index: index)
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
            .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
                handleDrop(providers: providers)
            }
            .overlay {
                if dropTargeted {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .background(Color.accentColor.opacity(0.05))
                }
            }
            .contextMenu {
                DirectoryContextMenu(viewModel: viewModel, fileOps: fileOps)
            }
        }
    }

    // MARK: - Parent Row

    private var parentRow: some View {
        FileRowView(
            item: FileItem.parentDirectory(for: viewModel.currentPath),
            isSelected: false,
            isCursor: viewModel.cursorItem == "..",
            showIcons: appState.showIconsInFileList,
            columnConfig: appState.columnConfig,
            fontSize: appState.fontSize,
            isRenaming: false,
            renameText: .constant("")
        )
        .tag("..")
        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
        .listRowBackground(
            viewModel.cursorItem == ".." ? AppTheme.rowCursorBackground : Color.clear
        )
        .onTapGesture(count: 2) {
            Task { await viewModel.goUp() }
        }
        .onTapGesture {
            viewModel.cursorItem = ".."
        }
    }

    // MARK: - File Row

    private func fileRow(item: FileItem, index: Int) -> some View {
        let isRenaming = viewModel.renamingItemId == item.id

        return FileRowView(
            item: item,
            isSelected: viewModel.selectedItems.contains(item.id),
            isCursor: viewModel.cursorItem == item.id,
            showIcons: appState.showIconsInFileList,
            columnConfig: appState.columnConfig,
            fontSize: appState.fontSize,
            isRenaming: isRenaming,
            renameText: Binding(
                get: { viewModel.renameText },
                set: { viewModel.renameText = $0 }
            ),
            onRenameCommit: {
                Task { await viewModel.commitRename() }
            },
            onRenameCancel: {
                viewModel.cancelRename()
            }
        )
        .tag(item.id)
        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
        .listRowBackground(rowBackground(for: item, index: index))
        .onTapGesture(count: 2) {
            Task { await viewModel.enterDirectory(item) }
        }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                viewModel.toggleSelection(item.id)
            } else if NSEvent.modifierFlags.contains(.shift) {
                selectRange(to: item)
            }
            viewModel.cursorItem = item.id
        }
        .contextMenu {
            FileContextMenu(
                item: item,
                viewModel: viewModel,
                fileOps: fileOps,
                otherPanelPath: otherPanelPath
            )
        }
        .draggable(URL(fileURLWithPath: item.path)) {
            HStack(spacing: 4) {
                Image(systemName: item.icon)
                    .foregroundColor(AppTheme.colorForFileType(item.iconColor))
                Text(viewModel.selectedItems.count > 1
                     ? "\(viewModel.selectedItems.count) items"
                     : item.name)
                    .font(.system(size: 12))
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
        }
    }

    // MARK: - Selection

    private func selectRange(to item: FileItem) {
        guard let cursorId = viewModel.cursorItem,
              let cursorIdx = viewModel.filteredItems.firstIndex(where: { $0.id == cursorId }),
              let targetIdx = viewModel.filteredItems.firstIndex(where: { $0.id == item.id }) else { return }
        let range = min(cursorIdx, targetIdx)...max(cursorIdx, targetIdx)
        for i in range {
            viewModel.selectedItems.insert(viewModel.filteredItems[i].id)
        }
    }

    // MARK: - Row Background

    private func rowBackground(for item: FileItem, index: Int) -> some View {
        Group {
            if viewModel.selectedItems.contains(item.id) && viewModel.cursorItem == item.id {
                AppTheme.rowSelectedBackground
            } else if viewModel.selectedItems.contains(item.id) {
                AppTheme.rowSelectedBackground.opacity(0.7)
            } else if viewModel.cursorItem == item.id {
                AppTheme.rowCursorBackground
            } else if index % 2 == 1 {
                AppTheme.rowAlternateBackground
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    let source = url.path
                    let dest = viewModel.currentPath
                    let provider = FileSystemRegistry.shared.provider(for: source)
                    try? await provider.copyItems(from: [source], to: dest)
                    await viewModel.loadDirectory(showHidden: appState.showHiddenFiles)
                }
            }
        }
        return true
    }
}

// MARK: - Column Header
struct ColumnHeaderView: View {
    @ObservedObject var viewModel: PanelViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
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
