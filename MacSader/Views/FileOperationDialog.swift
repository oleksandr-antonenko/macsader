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

                // Hint for relative paths
                if fileOps.dialogType == .copy || fileOps.dialogType == .move {
                    Text("Use ./ for current folder, or a full path. Include filename to rename.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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

    // MARK: - Resolve destination path

    /// Resolves user input to an absolute path.
    /// - "./newname.txt" -> currentDir/newname.txt
    /// - "../foo"        -> parentDir/foo
    /// - "newname.txt"   -> currentDir/newname.txt (for single item rename-copy)
    /// - "/abs/path"     -> as-is
    private func resolveDestination(_ input: String, forSources sources: [String]) -> (directory: String, newName: String?) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentDir = activePanel.currentPath

        // Absolute path or remote URL
        if trimmed.hasPrefix("/") || trimmed.contains("://") {
            return resolveAbsolutePath(trimmed)
        }

        // Relative path starting with ./ or ../
        if trimmed.hasPrefix("./") {
            let name = String(trimmed.dropFirst(2))
            if name.contains("/") {
                // Subdirectory path: ./subdir/name
                let fullPath = (currentDir as NSString).appendingPathComponent(name)
                return resolveAbsolutePath(fullPath)
            }
            // Simple: ./newname -> copy to current dir with new name
            return (currentDir, name)
        }

        if trimmed.hasPrefix("../") {
            let parent = (currentDir as NSString).deletingLastPathComponent
            let rest = String(trimmed.dropFirst(3))
            let fullPath = (parent as NSString).appendingPathComponent(rest)
            return resolveAbsolutePath(fullPath)
        }

        // Bare name without any slash -> copy to current dir with new name
        if !trimmed.contains("/") {
            return (currentDir, trimmed)
        }

        // Some other relative path — shouldn't normally happen, treat as-is
        return resolveAbsolutePath(trimmed)
    }

    private func resolveAbsolutePath(_ path: String) -> (directory: String, newName: String?) {
        var isDir: ObjCBool = false

        // If path is an existing directory, copy into it (keep original name)
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            return (path, nil)
        }

        // Path is a file or doesn't exist — split into dir + filename
        let dir = (path as NSString).deletingLastPathComponent
        let name = (path as NSString).lastPathComponent

        if FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue {
            return (dir, name)
        }

        // Directory doesn't exist either — return as-is, will get error at copy time
        return (path, nil)
    }

    // MARK: - Dialog properties

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

    // MARK: - Execute

    private func executeAction() async {
        errorMessage = nil
        do {
            switch fileOps.dialogType {
            case .copy:
                let sources = activePanel.selectedPaths
                let (destDir, newName) = resolveDestination(fileOps.dialogInput, forSources: sources)
                if let newName = newName, sources.count == 1 {
                    // Copy single file with rename
                    try await fileOps.executeCopyWithRename(
                        source: sources[0],
                        destinationDir: destDir,
                        newName: newName
                    )
                } else {
                    try await fileOps.executeCopy(sources: sources, destination: destDir)
                }
                await activePanel.loadDirectory(showHidden: false)
                await otherPanel.loadDirectory(showHidden: false)

            case .move:
                let sources = activePanel.selectedPaths
                let (destDir, newName) = resolveDestination(fileOps.dialogInput, forSources: sources)
                if let newName = newName, sources.count == 1 {
                    try await fileOps.executeMoveWithRename(
                        source: sources[0],
                        destinationDir: destDir,
                        newName: newName
                    )
                } else {
                    try await fileOps.executeMove(sources: sources, destination: destDir)
                }
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
