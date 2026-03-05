import SwiftUI

struct BookmarksSheet: View {
    @EnvironmentObject var appState: AppState
    let onNavigate: (String) -> Void

    @State private var newName = ""
    @State private var newPath = ""
    @State private var isAddingNew = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bookmarks")
                    .font(.headline)
                Spacer()
                Button {
                    isAddingNew.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("Add Bookmark")
            }
            .padding()

            Divider()

            // Add new bookmark form
            if isAddingNew {
                VStack(spacing: 8) {
                    TextField("Name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Path (e.g., /path or sftp://host/path)", text: $newPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            isAddingNew = false
                            newName = ""
                            newPath = ""
                        }
                        Button("Add") {
                            if !newName.isEmpty && !newPath.isEmpty {
                                appState.addBookmark(name: newName, path: newPath)
                                isAddingNew = false
                                newName = ""
                                newPath = ""
                            }
                        }
                        .disabled(newName.isEmpty || newPath.isEmpty)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()
            }

            // Bookmark categories
            List {
                ForEach(BookmarkCategory.allCases, id: \.self) { category in
                    let categoryBookmarks = appState.bookmarks.filter { $0.category == category }
                    if !categoryBookmarks.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryBookmarks) { bookmark in
                                BookmarkRow(bookmark: bookmark) {
                                    onNavigate(bookmark.path)
                                    appState.showBookmarks = false
                                } onDelete: {
                                    appState.removeBookmark(bookmark)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Close button
            HStack {
                Spacer()
                Button("Close") {
                    appState.showBookmarks = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    let onNavigate: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: bookmark.icon)
                .foregroundColor(bookmark.isRemote ? .orange : .blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(bookmark.name)
                    .font(.system(size: 13))
                Text(bookmark.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let shortcut = bookmark.shortcut {
                Text(shortcut)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(3)
            }

            if isHovering && bookmark.category == .user || bookmark.category == .remote {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onNavigate() }
        .onTapGesture {} // Absorb single tap
        .onHover { isHovering = $0 }
    }
}
