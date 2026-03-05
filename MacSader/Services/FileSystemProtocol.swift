import Foundation

protocol FileSystemProvider {
    var scheme: String { get }
    var displayName: String { get }

    func listDirectory(at path: String) async throws -> [FileItem]
    func createDirectory(at path: String, name: String) async throws
    func deleteItems(_ paths: [String]) async throws
    func copyItems(from sources: [String], to destination: String) async throws
    func moveItems(from sources: [String], to destination: String) async throws
    func rename(at path: String, to newName: String) async throws
    func fileExists(at path: String) async -> Bool
    func isDirectory(at path: String) async -> Bool
    func resolveSymlink(at path: String) async throws -> String
}

extension FileSystemProvider {
    func resolveSymlink(at path: String) async throws -> String { path }
}

enum FileSystemError: LocalizedError {
    case notFound(String)
    case permissionDenied(String)
    case alreadyExists(String)
    case notADirectory(String)
    case connectionFailed(String)
    case operationCancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let path): return "Not found: \(path)"
        case .permissionDenied(let path): return "Permission denied: \(path)"
        case .alreadyExists(let path): return "Already exists: \(path)"
        case .notADirectory(let path): return "Not a directory: \(path)"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .operationCancelled: return "Operation cancelled"
        case .unknown(let msg): return msg
        }
    }
}

class FileSystemRegistry {
    static let shared = FileSystemRegistry()
    private var providers: [String: FileSystemProvider] = [:]

    private init() {
        register(LocalFileSystem())
    }

    func register(_ provider: FileSystemProvider) {
        providers[provider.scheme] = provider
    }

    func provider(for path: String) -> FileSystemProvider {
        if let url = URL(string: path), let scheme = url.scheme, scheme != "file" {
            return providers[scheme] ?? providers["file"]!
        }
        return providers["file"]!
    }

    func provider(forScheme scheme: String) -> FileSystemProvider? {
        providers[scheme]
    }

    var availableSchemes: [String] {
        Array(providers.keys).sorted()
    }
}
