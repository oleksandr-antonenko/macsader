import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable, Comparable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let permissions: String
    let owner: String
    let isHidden: Bool
    let isSymlink: Bool
    let utType: UTType?

    var displaySize: String {
        if isDirectory { return "<DIR>" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(modificationDate) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDate(modificationDate, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM dd HH:mm"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return formatter.string(from: modificationDate)
    }

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        if isSymlink { return "arrow.triangle.branch" }
        switch fileExtension {
        case "swift", "py", "js", "ts", "rs", "go", "c", "cpp", "h", "java", "rb", "php":
            return "chevron.left.forwardslash.chevron.right"
        case "json", "yml", "yaml", "xml", "plist", "toml":
            return "doc.text"
        case "md", "txt", "rtf", "log":
            return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "heic", "tiff", "bmp", "ico":
            return "photo"
        case "mp4", "mov", "avi", "mkv", "webm":
            return "film"
        case "mp3", "wav", "aac", "flac", "m4a", "ogg":
            return "music.note"
        case "zip", "tar", "gz", "bz2", "rar", "7z", "xz", "dmg":
            return "archivebox"
        case "pdf":
            return "doc.richtext"
        case "app":
            return "app.badge.fill"
        case "sh", "bash", "zsh", "fish":
            return "terminal"
        default:
            return "doc"
        }
    }

    var iconColor: String {
        if isDirectory { return "folder" }
        if isSymlink { return "symlink" }
        switch fileExtension {
        case "swift": return "code-swift"
        case "py": return "code-python"
        case "js", "ts": return "code-js"
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "heic": return "image"
        case "mp4", "mov", "avi", "mkv": return "video"
        case "mp3", "wav", "aac", "flac": return "audio"
        case "zip", "tar", "gz", "dmg", "rar": return "archive"
        default: return "default"
        }
    }

    static func < (lhs: FileItem, rhs: FileItem) -> Bool {
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    static func parentDirectory(for path: String) -> FileItem {
        FileItem(
            id: "..",
            name: "..",
            path: (path as NSString).deletingLastPathComponent,
            isDirectory: true,
            size: 0,
            modificationDate: Date(),
            creationDate: Date(),
            permissions: "",
            owner: "",
            isHidden: false,
            isSymlink: false,
            utType: nil
        )
    }
}
