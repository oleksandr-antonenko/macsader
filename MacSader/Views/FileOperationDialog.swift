import SwiftUI

struct FileOperationDialog: View {
    @ObservedObject var fileOps: FileOperationViewModel
    let activePanel: PanelViewModel
    let otherPanel: PanelViewModel

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: dialogIcon)
                    .font(.title2)
                    .foregroundColor(dialogColor)
                Text(dialogTitle)
                    .font(.headline)
                Spacer()
            }

            // Message
            Text(fileOps.dialogMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Input field (not for delete)
            if fileOps.dialogType != .delete {
                TextField("", text: $fileOps.dialogInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if fileOps.isProcessing {
                ProgressView(fileOps.progressMessage)
                    .controlSize(.small)
            }

            // Buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    fileOps.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(actionTitle) {
                    Task { await executeAction() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(fileOps.isProcessing || (fileOps.dialogType != .delete && fileOps.dialogInput.isEmpty))
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private var dialogTitle: String {
        switch fileOps.dialogType {
        case .copy: return "Copy"
        case .move: return "Move"
        case .mkdir: return "New Folder"
        case .delete: return "Delete"
        case .rename: return "Rename"
        case .none: return ""
        }
    }

    private var dialogIcon: String {
        switch fileOps.dialogType {
        case .copy: return "doc.on.doc"
        case .move: return "arrow.right.doc.on.clipboard"
        case .mkdir: return "folder.badge.plus"
        case .delete: return "trash"
        case .rename: return "pencil"
        case .none: return ""
        }
    }

    private var dialogColor: Color {
        fileOps.dialogType == .delete ? .red : .accentColor
    }

    private var actionTitle: String {
        switch fileOps.dialogType {
        case .copy: return "Copy"
        case .move: return "Move"
        case .mkdir: return "Create"
        case .delete: return "Delete"
        case .rename: return "Rename"
        case .none: return "OK"
        }
    }

    private func executeAction() async {
        errorMessage = nil
        do {
            switch fileOps.dialogType {
            case .copy:
                let sources = activePanel.selectedPaths
                try await fileOps.executeCopy(sources: sources, destination: fileOps.dialogInput)
                await otherPanel.loadDirectory(showHidden: false)

            case .move:
                let sources = activePanel.selectedPaths
                try await fileOps.executeMove(sources: sources, destination: fileOps.dialogInput)
                await activePanel.loadDirectory(showHidden: false)
                await otherPanel.loadDirectory(showHidden: false)

            case .mkdir:
                try await fileOps.executeMkdir(at: activePanel.currentPath, name: fileOps.dialogInput)
                await activePanel.loadDirectory(showHidden: false)

            case .delete:
                let paths = activePanel.selectedPaths
                try await fileOps.executeDelete(paths: paths)
                activePanel.selectedItems.removeAll()
                await activePanel.loadDirectory(showHidden: false)

            case .rename:
                guard let cursor = activePanel.cursorItem else { return }
                try await fileOps.executeRename(at: cursor, to: fileOps.dialogInput)
                await activePanel.loadDirectory(showHidden: false)

            case .none:
                break
            }
            fileOps.dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
