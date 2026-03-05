import SwiftUI

struct BottomToolbar: View {
    @ObservedObject var fileOps: FileOperationViewModel
    let activePanel: PanelViewModel
    let otherPanel: PanelViewModel

    var body: some View {
        HStack(spacing: 1) {
            toolbarButton("F3 View") {
                if let item = currentItem, !item.isDirectory {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                }
            }

            toolbarButton("F4 Edit") {
                if let item = currentItem, !item.isDirectory {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                }
            }

            toolbarButton("F5 Copy") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptCopy(items: items, destination: otherPanel.currentPath)
                }
            }

            toolbarButton("F6 Move") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptMove(items: items, destination: otherPanel.currentPath)
                }
            }

            toolbarButton("F7 Mkdir") {
                fileOps.promptMkdir(currentPath: activePanel.currentPath)
            }

            toolbarButton("F8 Delete") {
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptDelete(items: items)
                }
            }

            toolbarButton("F9 Terminal") {
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

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.toolbarHeight)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1),
            alignment: .trailing
        )
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
