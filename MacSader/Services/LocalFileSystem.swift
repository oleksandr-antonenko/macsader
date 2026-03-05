import Foundation
import UniformTypeIdentifiers

class LocalFileSystem: FileSystemProvider {
    let scheme = "file"
    let displayName = "Local"

    private let fileManager = FileManager.default

    func listDirectory(at path: String) async throws -> [FileItem] {
        let resolvedPath = (path as NSString).expandingTildeInPath

        guard fileManager.fileExists(atPath: resolvedPath) else {
            throw FileSystemError.notFound(resolvedPath)
        }

        let contents = try fileManager.contentsOfDirectory(atPath: resolvedPath)
        var items: [FileItem] = []

        for name in contents {
            let fullPath = (resolvedPath as NSString).appendingPathComponent(name)
            guard let item = makeFileItem(name: name, path: fullPath) else { continue }
            items.append(item)
        }

        return items
    }

    private func makeFileItem(name: String, path: String) -> FileItem? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else { return nil }

        let attrs = try? fileManager.attributesOfItem(atPath: path)
        let size = (attrs?[.size] as? Int64) ?? 0
        let modDate = (attrs?[.modificationDate] as? Date) ?? Date()
        let createDate = (attrs?[.creationDate] as? Date) ?? Date()
        let posixPerms = (attrs?[.posixPermissions] as? Int) ?? 0
        let owner = (attrs?[.ownerAccountName] as? String) ?? ""
        let fileType = attrs?[.type] as? FileAttributeType
        let isSymlink = fileType == .typeSymbolicLink

        let permsString = formatPermissions(posixPerms, isDirectory: isDir.boolValue)
        let isHidden = name.hasPrefix(".")
        let utType = UTType(filenameExtension: (name as NSString).pathExtension)

        return FileItem(
            id: path,
            name: name,
            path: path,
            isDirectory: isDir.boolValue,
            size: size,
            modificationDate: modDate,
            creationDate: createDate,
            permissions: permsString,
            owner: owner,
            isHidden: isHidden,
            isSymlink: isSymlink,
            utType: utType
        )
    }

    private func formatPermissions(_ posix: Int, isDirectory: Bool) -> String {
        let perms = [
            (posix & 0o400 != 0) ? "r" : "-",
            (posix & 0o200 != 0) ? "w" : "-",
            (posix & 0o100 != 0) ? "x" : "-",
            (posix & 0o040 != 0) ? "r" : "-",
            (posix & 0o020 != 0) ? "w" : "-",
            (posix & 0o010 != 0) ? "x" : "-",
            (posix & 0o004 != 0) ? "r" : "-",
            (posix & 0o002 != 0) ? "w" : "-",
            (posix & 0o001 != 0) ? "x" : "-",
        ]
        let prefix = isDirectory ? "d" : "-"
        return prefix + perms.joined()
    }

    func createDirectory(at path: String, name: String) async throws {
        let fullPath = (path as NSString).appendingPathComponent(name)
        guard !fileManager.fileExists(atPath: fullPath) else {
            throw FileSystemError.alreadyExists(fullPath)
        }
        try fileManager.createDirectory(atPath: fullPath, withIntermediateDirectories: false)
    }

    func deleteItems(_ paths: [String]) async throws {
        for path in paths {
            guard fileManager.fileExists(atPath: path) else {
                throw FileSystemError.notFound(path)
            }
            try fileManager.removeItem(atPath: path)
        }
    }

    func copyItems(from sources: [String], to destination: String) async throws {
        for source in sources {
            let name = (source as NSString).lastPathComponent
            let destPath = (destination as NSString).appendingPathComponent(name)
            try fileManager.copyItem(atPath: source, toPath: destPath)
        }
    }

    func moveItems(from sources: [String], to destination: String) async throws {
        for source in sources {
            let name = (source as NSString).lastPathComponent
            let destPath = (destination as NSString).appendingPathComponent(name)
            try fileManager.moveItem(atPath: source, toPath: destPath)
        }
    }

    func rename(at path: String, to newName: String) async throws {
        let dir = (path as NSString).deletingLastPathComponent
        let newPath = (dir as NSString).appendingPathComponent(newName)
        guard !fileManager.fileExists(atPath: newPath) else {
            throw FileSystemError.alreadyExists(newPath)
        }
        try fileManager.moveItem(atPath: path, toPath: newPath)
    }

    func fileExists(at path: String) async -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func isDirectory(at path: String) async -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    func resolveSymlink(at path: String) async throws -> String {
        try fileManager.destinationOfSymbolicLink(atPath: path)
    }
}
