import SwiftUI

struct BottomToolbar: View {
    @ObservedObject var fileOps: FileOperationViewModel
    let activePanel: PanelViewModel
    let otherPanel: PanelViewModel

    @State private var hoveredButton: String?

    var body: some View {
        HStack(spacing: 0) {
            fButton("F2", "Rename", "pencil") {
                activePanel.startRename()
            }

            fButton("F3", "View", "eye") {
                if let item = currentItem, !item.isDirectory {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                }
            }

            fButton("F4", "Edit", "square.and.pencil") {
                if let item = currentItem, !item.isDirectory {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                }
            }

            fButton("F5", "Copy", "doc.on.doc") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptCopy(items: items, destination: otherPanel.currentPath)
                }
            }

            fButton("F6", "Move", "arrow.right") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptMove(items: items, destination: otherPanel.currentPath)
                }
            }

            fButton("F7", "Mkdir", "folder.badge.plus") {
                fileOps.promptMkdir(currentPath: activePanel.currentPath)
            }

            fButton("F8", "Delete", "trash") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptDelete(items: items)
                }
            }

            fButton("F9", "Term", "terminal") {
                openTerminal(at: activePanel.currentPath)
            }
        }
        .frame(height: AppTheme.toolbarHeight)
        .background(AppTheme.toolbarBackground)
    }

    private var currentItem: FileItem? {
        guard let cursor = activePanel.cursorItem else { return nil }
        return activePanel.filteredItems.first { $0.id == cursor }
    }

    private func fButton(_ key: String, _ label: String, _ icon: String, action: @escaping () -> Void) -> some View {
        let id = key
        return Button(action: action) {
            HStack(spacing: 3) {
                Text(key)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(hoveredButton == id ? .accentColor : .secondary.opacity(0.6))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(hoveredButton == id ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.toolbarHeight)
            .background(
                hoveredButton == id
                    ? Color.accentColor.opacity(0.1)
                    : Color(nsColor: .controlBackgroundColor).opacity(0.15)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            hoveredButton = isHovered ? id : nil
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.5))
                .frame(width: 1)
        }
    }

    private func openTerminal(at path: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd \(path.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
