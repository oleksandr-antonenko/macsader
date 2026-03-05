import Foundation
import SwiftUI
import Combine

@MainActor
class PanelViewModel: ObservableObject {
    let side: PanelSide

    @Published var tabs: [PanelTab] = []
    @Published var activeTabId: UUID?
    @Published var items: [FileItem] = []
    @Published var filteredItems: [FileItem] = []
    @Published var selectedItems: Set<String> = []
    @Published var cursorItem: String?
    @Published var sortField: SortField = .name
    @Published var sortOrder: SortOrder = .ascending
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var quickSearchText: String = ""
    @Published var isQuickSearchActive: Bool = false
    @Published var history: [String] = []
    @Published var historyIndex: Int = -1

    private var showHidden: Bool = false
    private let fs = FileSystemRegistry.shared

    var currentPath: String {
        activeTab?.path ?? NSHomeDirectory()
    }

    var activeTab: PanelTab? {
        tabs.first { $0.id == activeTabId }
    }

    var activeTabIndex: Int? {
        tabs.firstIndex { $0.id == activeTabId }
    }

    var pathComponents: [(name: String, path: String)] {
        let path = currentPath
        var components: [(String, String)] = []
        var current = path

        if path.contains("://") {
            // Remote path
            if let url = URL(string: path) {
                let scheme = url.scheme ?? ""
                let host = url.host ?? ""
                components.append(("\(scheme)://\(host)", "\(scheme)://\(host)/"))
                let pathParts = url.path.split(separator: "/")
                var buildPath = "\(scheme)://\(host)"
                for part in pathParts {
                    buildPath += "/\(part)"
                    components.append((String(part), buildPath))
                }
            }
        } else {
            components.append(("/", "/"))
            let parts = path.split(separator: "/")
            var buildPath = ""
            for part in parts {
                buildPath += "/\(part)"
                components.append((String(part), buildPath))
            }
        }

        return components
    }

    init(side: PanelSide) {
        self.side = side
        let home = NSHomeDirectory()
        let initialTab = PanelTab(path: home)
        self.tabs = [initialTab]
        self.activeTabId = initialTab.id
    }

    func loadDirectory(showHidden: Bool = false) async {
        self.showHidden = showHidden
        let path = currentPath
        isLoading = true
        error = nil

        do {
            let provider = fs.provider(for: path)
            let allItems = try await provider.listDirectory(at: path)
            let filtered = showHidden ? allItems : allItems.filter { !$0.isHidden }
            self.items = sortItems(filtered)
            applyQuickSearch()

            if cursorItem == nil, let first = filteredItems.first {
                cursorItem = first.id
            }
        } catch {
            self.error = error.localizedDescription
            self.items = []
            self.filteredItems = []
        }

        isLoading = false
    }

    private func sortItems(_ items: [FileItem]) -> [FileItem] {
        items.sorted { a, b in
            // Directories always first
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }

            let result: Bool
            switch sortField {
            case .name:
                result = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .size:
                result = a.size < b.size
            case .date:
                result = a.modificationDate < b.modificationDate
            case .ext:
                let extCompare = a.fileExtension.localizedStandardCompare(b.fileExtension)
                if extCompare == .orderedSame {
                    result = a.name.localizedStandardCompare(b.name) == .orderedAscending
                } else {
                    result = extCompare == .orderedAscending
                }
            }

            return sortOrder == .ascending ? result : !result
        }
    }

    func applyQuickSearch() {
        if quickSearchText.isEmpty {
            filteredItems = items
        } else {
            let query = quickSearchText.lowercased()
            filteredItems = items.filter { $0.name.lowercased().contains(query) }
        }
    }

    func navigate(to path: String) async {
        guard let tabIndex = activeTabIndex else { return }

        // Push current path to history
        let oldPath = tabs[tabIndex].path
        if history.isEmpty || history.last != oldPath {
            // Trim forward history if we navigated back
            if historyIndex < history.count - 1 {
                history = Array(history.prefix(historyIndex + 1))
            }
            history.append(oldPath)
            historyIndex = history.count - 1
        }

        tabs[tabIndex].path = path
        tabs[tabIndex].title = (path as NSString).lastPathComponent
        selectedItems.removeAll()
        cursorItem = nil
        quickSearchText = ""
        isQuickSearchActive = false
        await loadDirectory(showHidden: showHidden)
    }

    func goUp() async {
        let parent = (currentPath as NSString).deletingLastPathComponent
        if parent != currentPath {
            let previousDir = (currentPath as NSString).lastPathComponent
            await navigate(to: parent)
            // Move cursor to the directory we came from
            if let item = filteredItems.first(where: { $0.name == previousDir }) {
                cursorItem = item.id
            }
        }
    }

    func goBack() async {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        let path = history[historyIndex]
        guard let tabIndex = activeTabIndex else { return }
        tabs[tabIndex].path = path
        tabs[tabIndex].title = (path as NSString).lastPathComponent
        selectedItems.removeAll()
        cursorItem = nil
        await loadDirectory(showHidden: showHidden)
    }

    func goForward() async {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        let path = history[historyIndex]
        guard let tabIndex = activeTabIndex else { return }
        tabs[tabIndex].path = path
        tabs[tabIndex].title = (path as NSString).lastPathComponent
        selectedItems.removeAll()
        cursorItem = nil
        await loadDirectory(showHidden: showHidden)
    }

    func enterDirectory(_ item: FileItem) async {
        if item.name == ".." {
            await goUp()
        } else if item.isDirectory {
            await navigate(to: item.path)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
        }
    }

    // MARK: - Selection

    func toggleSelection(_ itemId: String) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }

    func selectAll() {
        selectedItems = Set(filteredItems.map(\.id))
    }

    func invertSelection() {
        let all = Set(filteredItems.map(\.id))
        selectedItems = all.subtracting(selectedItems)
    }

    func moveCursor(direction: Int) {
        guard !filteredItems.isEmpty else { return }

        if let current = cursorItem,
           let index = filteredItems.firstIndex(where: { $0.id == current }) {
            let newIndex = max(0, min(filteredItems.count - 1, index + direction))
            cursorItem = filteredItems[newIndex].id
        } else {
            cursorItem = filteredItems.first?.id
        }
    }

    // MARK: - Tabs

    func addTab(path: String? = nil) {
        let newPath = path ?? currentPath
        let tab = PanelTab(path: newPath)
        tabs.append(tab)
        activeTabId = tab.id
        Task { await loadDirectory(showHidden: showHidden) }
    }

    func closeTab(_ tabId: UUID) {
        guard tabs.count > 1 else { return }
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }

        let wasActive = tabId == activeTabId
        tabs.remove(at: index)

        if wasActive {
            let newIndex = min(index, tabs.count - 1)
            activeTabId = tabs[newIndex].id
            Task { await loadDirectory(showHidden: showHidden) }
        }
    }

    func switchToTab(_ tabId: UUID) {
        guard tabId != activeTabId else { return }
        activeTabId = tabId
        Task { await loadDirectory(showHidden: showHidden) }
    }

    func nextTab() {
        guard let index = activeTabIndex, tabs.count > 1 else { return }
        let nextIndex = (index + 1) % tabs.count
        switchToTab(tabs[nextIndex].id)
    }

    func previousTab() {
        guard let index = activeTabIndex, tabs.count > 1 else { return }
        let prevIndex = (index - 1 + tabs.count) % tabs.count
        switchToTab(tabs[prevIndex].id)
    }

    func duplicateTab() {
        addTab(path: currentPath)
    }

    // MARK: - Sort

    func toggleSort(_ field: SortField) {
        if sortField == field {
            sortOrder.toggle()
        } else {
            sortField = field
            sortOrder = .ascending
        }
        items = sortItems(items)
        applyQuickSearch()
    }

    // MARK: - Helpers

    var selectedPaths: [String] {
        if selectedItems.isEmpty, let cursor = cursorItem {
            return [cursor]
        }
        return Array(selectedItems)
    }

    var selectedOrCursorItems: [FileItem] {
        let paths = Set(selectedPaths)
        return filteredItems.filter { paths.contains($0.id) }
    }
}
