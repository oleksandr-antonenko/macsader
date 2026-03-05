import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var activePanel: PanelSide = .left
    @Published var showHiddenFiles: Bool = false
    @Published var showBookmarks: Bool = false
    @Published var showPreview: Bool = false
    @Published var panelSplitRatio: CGFloat = 0.5
    @Published var bookmarks: [Bookmark] = []
    @Published var keyBindings: [KeyBinding] = KeyBindingDefaults.bindings
    @Published var columnConfig = ColumnConfig()

    // Theme
    @Published var fontSize: CGFloat = 13
    @Published var rowHeight: CGFloat = 24
    @Published var fontName: String = "SF Mono"
    @Published var showIconsInFileList: Bool = true

    private let settingsURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MacSader")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.settingsURL = appDir.appendingPathComponent("settings.json")

        loadSettings()
        setupDefaultBookmarks()
        registerProviders()
    }

    private func registerProviders() {
        FileSystemRegistry.shared.register(SFTPFileSystem())
    }

    private func setupDefaultBookmarks() {
        if bookmarks.isEmpty {
            let home = NSHomeDirectory()
            bookmarks = [
                Bookmark(name: "Home", path: home, icon: "house", category: .system),
                Bookmark(name: "Desktop", path: home + "/Desktop", icon: "menubar.dock.rectangle", category: .system),
                Bookmark(name: "Documents", path: home + "/Documents", icon: "doc.text", category: .system),
                Bookmark(name: "Downloads", path: home + "/Downloads", icon: "arrow.down.circle", category: .system),
                Bookmark(name: "Developer", path: home + "/Developer", icon: "hammer", category: .system),
                Bookmark(name: "Applications", path: "/Applications", icon: "app.badge.fill", category: .system),
                Bookmark(name: "Root", path: "/", icon: "externaldrive", category: .system),
            ]
        }
    }

    func addBookmark(name: String, path: String) {
        guard !bookmarks.contains(where: { $0.path == path && $0.category != .recent }) else { return }
        let category: BookmarkCategory = path.contains("://") ? .remote : .user
        let icon = path.contains("://") ? "network" : "folder"
        bookmarks.append(Bookmark(name: name, path: path, icon: icon, category: category))
        saveSettings()
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveSettings()
    }

    func binding(for action: KeyAction) -> KeyBinding? {
        keyBindings.first { $0.action == action }
    }

    func saveSettings() {
        let data = AppSettings(
            bookmarks: bookmarks.filter { $0.category != .system },
            showHiddenFiles: showHiddenFiles,
            fontSize: fontSize,
            rowHeight: rowHeight,
            fontName: fontName,
            showIconsInFileList: showIconsInFileList,
            columnConfig: columnConfig
        )
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: settingsURL)
        }
    }

    private func loadSettings() {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else { return }
        self.showHiddenFiles = settings.showHiddenFiles
        self.fontSize = settings.fontSize
        self.rowHeight = settings.rowHeight
        self.fontName = settings.fontName
        self.showIconsInFileList = settings.showIconsInFileList
        self.columnConfig = settings.columnConfig
        self.bookmarks = settings.bookmarks
    }
}

struct AppSettings: Codable {
    var bookmarks: [Bookmark]
    var showHiddenFiles: Bool
    var fontSize: CGFloat
    var rowHeight: CGFloat
    var fontName: String
    var showIconsInFileList: Bool
    var columnConfig: ColumnConfig
}
