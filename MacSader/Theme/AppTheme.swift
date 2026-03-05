import SwiftUI

struct AppTheme {
    // File type colors
    static func colorForFileType(_ type: String) -> Color {
        switch type {
        case "folder": return .blue
        case "symlink": return .cyan
        case "code-swift": return .orange
        case "code-python": return .green
        case "code-js": return .yellow
        case "image": return .purple
        case "video": return .pink
        case "audio": return .mint
        case "archive": return .brown
        default: return .secondary
        }
    }

    // Panel
    static let panelBackground = Color(nsColor: .controlBackgroundColor)
    static let panelActiveAccent = Color.accentColor
    static let panelInactiveAccent = Color.secondary.opacity(0.5)

    // Rows
    static let rowSelectedBackground = Color.accentColor.opacity(0.2)
    static let rowCursorBackground = Color.accentColor.opacity(0.1)
    static let rowCursorBorder = Color.accentColor
    static let rowAlternateBackground = Color(nsColor: .controlBackgroundColor).opacity(0.5)

    // Tab bar
    static let tabBarBackground = Color(nsColor: .windowBackgroundColor)
    static let tabActiveBackground = Color(nsColor: .controlBackgroundColor)
    static let tabInactiveBackground = Color.clear

    // Path bar
    static let pathBarBackground = Color(nsColor: .textBackgroundColor)

    // Toolbar
    static let toolbarBackground = Color(nsColor: .windowBackgroundColor)
    static let toolbarButtonWidth: CGFloat = 90

    // Sizes
    static let tabHeight: CGFloat = 30
    static let pathBarHeight: CGFloat = 28
    static let toolbarHeight: CGFloat = 32
    static let dividerWidth: CGFloat = 4
    static let minPanelWidth: CGFloat = 200
}
