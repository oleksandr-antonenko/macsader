import Foundation

// SFTP provider using ssh/sftp command-line tools as backend.
// For a production app, this would use libssh2 or NMSSH framework.
// This implementation provides the architecture and a working subprocess-based approach.
class SFTPFileSystem: FileSystemProvider {
    let scheme = "sftp"
    let displayName = "SFTP"

    struct ConnectionInfo {
        let host: String
        let port: Int
        let user: String
        let path: String

        init?(from urlString: String) {
            guard let url = URL(string: urlString) else { return nil }
            self.host = url.host ?? ""
            self.port = url.port ?? 22
            self.user = url.user ?? NSUserName()
            self.path = url.path.isEmpty ? "/" : url.path
        }
    }

    func listDirectory(at path: String) async throws -> [FileItem] {
        guard let conn = ConnectionInfo(from: path) else {
            throw FileSystemError.connectionFailed("Invalid SFTP URL: \(path)")
        }

        let command = "ls -la \(conn.path)"
        let output = try await executeRemoteCommand(command, connection: conn)
        return parseListOutput(output, basePath: path, remotePath: conn.path)
    }

    private func executeRemoteCommand(_ command: String, connection: ConnectionInfo) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        var args = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=10"]
        if connection.port != 22 {
            args += ["-p", "\(connection.port)"]
        }
        args += ["\(connection.user)@\(connection.host)", command]
        process.arguments = args

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus != 0 {
                    let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: FileSystemError.connectionFailed(errorMsg))
                } else {
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: FileSystemError.connectionFailed(error.localizedDescription))
            }
        }
    }

    private func parseListOutput(_ output: String, basePath: String, remotePath: String) -> [FileItem] {
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("total") }
        var items: [FileItem] = []

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for line in lines {
            let parts = line.split(separator: " ", maxSplits: 8, omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 9 else { continue }

            let permissions = parts[0]
            let owner = parts[2]
            let size = Int64(parts[4]) ?? 0
            let name = parts[8]
            let isDirectory = permissions.hasPrefix("d")
            let isSymlink = permissions.hasPrefix("l")

            if name == "." || name == ".." { continue }

            let fullRemotePath = (remotePath as NSString).appendingPathComponent(name)
            let scheme = basePath.components(separatedBy: remotePath).first ?? "sftp://"
            let fullPath = scheme + fullRemotePath

            items.append(FileItem(
                id: fullPath,
                name: name,
                path: fullPath,
                isDirectory: isDirectory,
                size: size,
                modificationDate: Date(),
                creationDate: Date(),
                permissions: permissions,
                owner: owner,
                isHidden: name.hasPrefix("."),
                isSymlink: isSymlink,
                utType: nil
            ))
        }

        return items
    }

    func createDirectory(at path: String, name: String) async throws {
        guard let conn = ConnectionInfo(from: path) else {
            throw FileSystemError.connectionFailed("Invalid SFTP URL")
        }
        let remotePath = (conn.path as NSString).appendingPathComponent(name)
        _ = try await executeRemoteCommand("mkdir \(remotePath)", connection: conn)
    }

    func deleteItems(_ paths: [String]) async throws {
        for path in paths {
            guard let conn = ConnectionInfo(from: path) else { continue }
            _ = try await executeRemoteCommand("rm -rf \(conn.path)", connection: conn)
        }
    }

    func copyItems(from sources: [String], to destination: String) async throws {
        // For remote-to-remote copy, use scp or rsync
        guard let destConn = ConnectionInfo(from: destination) else {
            throw FileSystemError.connectionFailed("Invalid destination")
        }
        for source in sources {
            guard let srcConn = ConnectionInfo(from: source) else { continue }
            let name = (srcConn.path as NSString).lastPathComponent
            let destPath = (destConn.path as NSString).appendingPathComponent(name)
            _ = try await executeRemoteCommand("cp -r \(srcConn.path) \(destPath)", connection: destConn)
        }
    }

    func moveItems(from sources: [String], to destination: String) async throws {
        guard let destConn = ConnectionInfo(from: destination) else {
            throw FileSystemError.connectionFailed("Invalid destination")
        }
        for source in sources {
            guard let srcConn = ConnectionInfo(from: source) else { continue }
            let name = (srcConn.path as NSString).lastPathComponent
            let destPath = (destConn.path as NSString).appendingPathComponent(name)
            _ = try await executeRemoteCommand("mv \(srcConn.path) \(destPath)", connection: destConn)
        }
    }

    func rename(at path: String, to newName: String) async throws {
        guard let conn = ConnectionInfo(from: path) else {
            throw FileSystemError.connectionFailed("Invalid SFTP URL")
        }
        let dir = (conn.path as NSString).deletingLastPathComponent
        let newPath = (dir as NSString).appendingPathComponent(newName)
        _ = try await executeRemoteCommand("mv \(conn.path) \(newPath)", connection: conn)
    }

    func fileExists(at path: String) async -> Bool {
        guard let conn = ConnectionInfo(from: path) else { return false }
        do {
            _ = try await executeRemoteCommand("test -e \(conn.path) && echo yes", connection: conn)
            return true
        } catch {
            return false
        }
    }

    func isDirectory(at path: String) async -> Bool {
        guard let conn = ConnectionInfo(from: path) else { return false }
        do {
            let result = try await executeRemoteCommand("test -d \(conn.path) && echo yes", connection: conn)
            return result.contains("yes")
        } catch {
            return false
        }
    }
}
