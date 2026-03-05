import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            AppearanceSettings()
                .environmentObject(appState)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            ColumnSettings()
                .environmentObject(appState)
                .tabItem { Label("Columns", systemImage: "tablecells") }

            KeyBindingSettings()
                .environmentObject(appState)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 500, height: 400)
        .padding()
    }
}

struct AppearanceSettings: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Font") {
                Picker("Font", selection: $appState.fontName) {
                    Text("SF Mono").tag("SF Mono")
                    Text("Menlo").tag("Menlo")
                    Text("Monaco").tag("Monaco")
                    Text("Courier New").tag("Courier New")
                    Text("JetBrains Mono").tag("JetBrains Mono")
                    Text("Fira Code").tag("Fira Code")
                }

                HStack {
                    Text("Font Size")
                    Slider(value: $appState.fontSize, in: 10...18, step: 1)
                    Text("\(Int(appState.fontSize))")
                        .frame(width: 24)
                }

                HStack {
                    Text("Row Height")
                    Slider(value: $appState.rowHeight, in: 18...36, step: 2)
                    Text("\(Int(appState.rowHeight))")
                        .frame(width: 24)
                }
            }

            Section("Display") {
                Toggle("Show file icons", isOn: $appState.showIconsInFileList)
                Toggle("Show hidden files", isOn: $appState.showHiddenFiles)
            }
        }
        .formStyle(.grouped)
        .onChange(of: appState.fontSize) { _, _ in appState.saveSettings() }
        .onChange(of: appState.rowHeight) { _, _ in appState.saveSettings() }
        .onChange(of: appState.fontName) { _, _ in appState.saveSettings() }
        .onChange(of: appState.showIconsInFileList) { _, _ in appState.saveSettings() }
    }
}

struct ColumnSettings: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Visible Columns") {
                Toggle("Extension", isOn: $appState.columnConfig.showExtension)
                Toggle("Size", isOn: $appState.columnConfig.showSize)
                Toggle("Date", isOn: $appState.columnConfig.showDate)
                Toggle("Permissions", isOn: $appState.columnConfig.showPermissions)
                Toggle("Owner", isOn: $appState.columnConfig.showOwner)
            }

            Section("Column Widths") {
                HStack {
                    Text("Extension")
                    Slider(value: $appState.columnConfig.extWidth, in: 40...120, step: 10)
                    Text("\(Int(appState.columnConfig.extWidth))")
                        .frame(width: 30)
                }
                HStack {
                    Text("Size")
                    Slider(value: $appState.columnConfig.sizeWidth, in: 60...150, step: 10)
                    Text("\(Int(appState.columnConfig.sizeWidth))")
                        .frame(width: 30)
                }
                HStack {
                    Text("Date")
                    Slider(value: $appState.columnConfig.dateWidth, in: 80...200, step: 10)
                    Text("\(Int(appState.columnConfig.dateWidth))")
                        .frame(width: 30)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: appState.columnConfig) { _, _ in appState.saveSettings() }
    }
}

struct KeyBindingSettings: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            ForEach(Array(KeyAction.allCases.enumerated()), id: \.element) { _, action in
                HStack {
                    Text(action.rawValue)
                        .frame(width: 150, alignment: .leading)

                    Spacer()

                    if let binding = appState.binding(for: action) {
                        Text(binding.displayString)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                    } else {
                        Text("Not set")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
