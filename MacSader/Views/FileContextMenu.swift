import SwiftUI

struct FileContextMenu: View {
    let item: FileItem
    let viewModel: PanelViewModel
    let fileOps: FileOperationViewModel
    let otherPanelPath: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            // Open
            Button {
                Task { await viewModel.enterDirectory(item) }
            } label: {
                Label(item.isDirectory ? "Open" : "Open File", systemImage: item.isDirectory ? "folder" : "doc")
            }

            if !item.isDirectory {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                } label: {
                    Label("Reveal in Finder", systemImage: "magnifyingglass")
                }
            }

            Divider()

            // Edit operations
            Button {
                viewModel.startRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                fileOps.promptCopy(items: [item], destination: otherPanelPath)
            } label: {
                Label("Copy to Other Panel", systemImage: "doc.on.doc")
            }

            Button {
                fileOps.promptMove(items: [item], destination: otherPanelPath)
            } label: {
                Label("Move to Other Panel", systemImage: "arrow.right.doc.on.clipboard")
            }

            Divider()

            Button(role: .destructive) {
                fileOps.promptDelete(items: [item])
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Divider()

            // Clipboard
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.clipboard")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.name, forType: .string)
            } label: {
                Label("Copy Name", systemImage: "textformat")
            }

            Divider()

            // Info
            Button {
                showGetInfo(for: item.path)
            } label: {
                Label("Get Info", systemImage: "info.circle")
            }

            if !item.isDirectory {
                Button {
                    NSWorkspace.shared.open(
                        [URL(fileURLWithPath: item.path)],
                        withApplicationAt: URL(fileURLWithPath: "/System/Applications/TextEdit.app"),
                        configuration: NSWorkspace.OpenConfiguration()
                    )
                } label: {
                    Label("Open with TextEdit", systemImage: "square.and.pencil")
                }
            }

            // Open in Terminal
            if item.isDirectory {
                Divider()

                Button {
                    openTerminal(at: item.path)
                } label: {
                    Label("Open in Terminal", systemImage: "terminal")
                }

                Button {
                    Task { await viewModel.navigate(to: item.path) }
                } label: {
                    Label("Open in New Tab", systemImage: "plus.rectangle.on.rectangle")
                }
            }
        }
    }

    private func showGetInfo(for path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
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

struct DirectoryContextMenu: View {
    let viewModel: PanelViewModel
    let fileOps: FileOperationViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            fileOps.promptMkdir(currentPath: viewModel.currentPath)
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }

        Divider()

        Button {
            viewModel.copyPathToClipboard()
        } label: {
            Label("Copy Current Path", systemImage: "doc.on.clipboard")
        }

        Button {
            openTerminal(at: viewModel.currentPath)
        } label: {
            Label("Open in Terminal", systemImage: "terminal")
        }

        Divider()

        Button {
            Task { await viewModel.loadDirectory(showHidden: appState.showHiddenFiles) }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }

        Button {
            viewModel.selectAll()
        } label: {
            Label("Select All", systemImage: "checkmark.circle")
        }

        Button {
            viewModel.invertSelection()
        } label: {
            Label("Invert Selection", systemImage: "arrow.triangle.swap")
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
