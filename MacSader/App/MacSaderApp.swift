import SwiftUI

@main
struct MacSaderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 700)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    // Handled via keyboard
                }
                .keyboardShortcut("t")

                Button("Close Tab") {}
                    .keyboardShortcut("w")

                Divider()

                Button("New Folder") {}
                    .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            // View menu
            CommandGroup(after: .toolbar) {
                Toggle("Show Hidden Files", isOn: $appState.showHiddenFiles)
                    .keyboardShortcut(".", modifiers: .command)

                Toggle("Show Preview", isOn: $appState.showPreview)
                    .keyboardShortcut("p")

                Divider()

                Toggle("Show Bookmarks", isOn: $appState.showBookmarks)
                    .keyboardShortcut("b")
            }

            // Go menu
            CommandMenu("Go") {
                Button("Back") {}
                    .keyboardShortcut("[")

                Button("Forward") {}
                    .keyboardShortcut("]")

                Button("Enclosing Folder") {}
                    .keyboardShortcut(.upArrow, modifiers: .command)

                Divider()

                Button("Home") {}
                    .keyboardShortcut("h", modifiers: [.command, .shift])

                Button("Root") {}

                Divider()

                Button("Go to Path...") {}
                    .keyboardShortcut("l")
            }
        }

        Settings {
            PreferencesView()
                .environmentObject(appState)
        }
    }
}
