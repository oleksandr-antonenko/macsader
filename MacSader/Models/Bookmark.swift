import Foundation

struct Bookmark: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var icon: String
    var shortcut: String?
    var category: BookmarkCategory

    init(name: String, path: String, icon: String = "folder", shortcut: String? = nil, category: BookmarkCategory = .user) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.icon = icon
        self.shortcut = shortcut
        self.category = category
    }

    var isRemote: Bool {
        path.contains("://")
    }

    var protocolType: String? {
        guard let scheme = URL(string: path)?.scheme else { return nil }
        return scheme
    }
}

enum BookmarkCategory: String, Codable, CaseIterable {
    case system = "System"
    case user = "Favorites"
    case remote = "Remote"
    case recent = "Recent"
}
