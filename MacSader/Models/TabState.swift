import Foundation

struct PanelTab: Identifiable, Equatable, Codable {
    let id: UUID
    var path: String
    var title: String
    var isLocked: Bool

    init(path: String, title: String? = nil, isLocked: Bool = false) {
        self.id = UUID()
        self.path = path
        self.title = title ?? (path as NSString).lastPathComponent
        self.isLocked = isLocked
    }

    var displayTitle: String {
        if title.isEmpty || title == "/" {
            return "/"
        }
        return title
    }
}
