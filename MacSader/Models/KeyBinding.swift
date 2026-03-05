import Foundation
import Carbon.HIToolbox

struct KeyBinding: Identifiable, Codable, Equatable {
    let id: UUID
    var action: KeyAction
    var key: String
    var modifiers: [KeyModifier]
    var isCustom: Bool

    init(action: KeyAction, key: String, modifiers: [KeyModifier] = [], isCustom: Bool = false) {
        self.id = UUID()
        self.action = action
        self.key = key
        self.modifiers = modifiers
        self.isCustom = isCustom
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("\u{2303}") }
        if modifiers.contains(.option) { parts.append("\u{2325}") }
        if modifiers.contains(.shift) { parts.append("\u{21E7}") }
        if modifiers.contains(.command) { parts.append("\u{2318}") }
        parts.append(key)
        return parts.joined()
    }
}

enum KeyModifier: String, Codable, CaseIterable {
    case command, option, control, shift
}

enum KeyAction: String, Codable, CaseIterable {
    // File operations
    case copy = "Copy"
    case move = "Move"
    case mkdir = "New Folder"
    case delete = "Delete"
    case rename = "Rename"
    case edit = "Edit"
    case view = "View"
    case refresh = "Refresh"

    // Navigation
    case goUp = "Go Up"
    case goHome = "Go Home"
    case goRoot = "Go Root"
    case enterDirectory = "Enter Directory"
    case goBack = "Go Back"
    case goForward = "Go Forward"
    case focusPathBar = "Focus Path Bar"
    case quickSearch = "Quick Search"
    case openTerminal = "Open Terminal"

    // Selection
    case selectAll = "Select All"
    case invertSelection = "Invert Selection"
    case selectByPattern = "Select by Pattern"

    // Tabs
    case newTab = "New Tab"
    case closeTab = "Close Tab"
    case nextTab = "Next Tab"
    case previousTab = "Previous Tab"
    case duplicateTab = "Duplicate Tab"

    // Panels
    case switchPanel = "Switch Panel"
    case swapPanels = "Swap Panels"
    case syncPanels = "Sync Panels"
    case equalPanels = "Equal Panels"

    // Bookmarks
    case addBookmark = "Add Bookmark"
    case showBookmarks = "Show Bookmarks"

    // View
    case toggleHidden = "Toggle Hidden Files"
    case togglePreview = "Toggle Preview"
}

struct KeyBindingDefaults {
    static let bindings: [KeyBinding] = [
        // Classic F-key bindings
        KeyBinding(action: .view, key: "F3"),
        KeyBinding(action: .edit, key: "F4"),
        KeyBinding(action: .copy, key: "F5"),
        KeyBinding(action: .move, key: "F6"),
        KeyBinding(action: .mkdir, key: "F7"),
        KeyBinding(action: .delete, key: "F8"),
        KeyBinding(action: .rename, key: "F2"),
        KeyBinding(action: .refresh, key: "F2", modifiers: [.command]),

        // Navigation
        KeyBinding(action: .goUp, key: "Left", modifiers: [.command]),
        KeyBinding(action: .goHome, key: "~"),
        KeyBinding(action: .goRoot, key: "/"),
        KeyBinding(action: .goBack, key: "[", modifiers: [.command]),
        KeyBinding(action: .goForward, key: "]", modifiers: [.command]),
        KeyBinding(action: .focusPathBar, key: "L", modifiers: [.command]),
        KeyBinding(action: .quickSearch, key: "F", modifiers: [.command]),
        KeyBinding(action: .openTerminal, key: "T", modifiers: [.command, .shift]),

        // Selection
        KeyBinding(action: .selectAll, key: "A", modifiers: [.command]),
        KeyBinding(action: .invertSelection, key: "*"),

        // Tabs
        KeyBinding(action: .newTab, key: "T", modifiers: [.command]),
        KeyBinding(action: .closeTab, key: "W", modifiers: [.command]),
        KeyBinding(action: .nextTab, key: "Tab", modifiers: [.control]),
        KeyBinding(action: .previousTab, key: "Tab", modifiers: [.control, .shift]),
        KeyBinding(action: .duplicateTab, key: "D", modifiers: [.command]),

        // Panels
        KeyBinding(action: .switchPanel, key: "Tab"),
        KeyBinding(action: .swapPanels, key: "U", modifiers: [.command]),
        KeyBinding(action: .syncPanels, key: "S", modifiers: [.command, .shift]),

        // Bookmarks
        KeyBinding(action: .addBookmark, key: "D", modifiers: [.command, .shift]),
        KeyBinding(action: .showBookmarks, key: "B", modifiers: [.command]),

        // View
        KeyBinding(action: .toggleHidden, key: ".", modifiers: [.command]),
        KeyBinding(action: .togglePreview, key: "P", modifiers: [.command]),
    ]
}
