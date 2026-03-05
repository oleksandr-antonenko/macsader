import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var leftPanel = PanelViewModel(side: .left)
    @StateObject private var rightPanel = PanelViewModel(side: .right)
    @StateObject private var fileOps = FileOperationViewModel()

    @State private var panelSplitRatio: CGFloat = 0.5
    @State private var isDraggingDivider = false
    @State private var fKeyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            // Main dual-panel area
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left panel
                    PanelView(
                        viewModel: leftPanel,
                        isActive: appState.activePanel == .left,
                        fileOps: fileOps,
                        otherPanelPath: rightPanel.currentPath
                    )
                    .frame(width: geometry.size.width * panelSplitRatio - AppTheme.dividerWidth / 2)
                    .onTapGesture { appState.activePanel = .left }

                    // Draggable divider
                    Rectangle()
                        .fill(isDraggingDivider ? Color.accentColor : Color(nsColor: .separatorColor))
                        .frame(width: AppTheme.dividerWidth)
                        .cursor(.resizeLeftRight)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingDivider = true
                                    let ratio = value.location.x / geometry.size.width
                                    panelSplitRatio = max(0.2, min(0.8, ratio))
                                }
                                .onEnded { _ in
                                    isDraggingDivider = false
                                }
                        )

                    // Right panel
                    PanelView(
                        viewModel: rightPanel,
                        isActive: appState.activePanel == .right,
                        fileOps: fileOps,
                        otherPanelPath: leftPanel.currentPath
                    )
                    .frame(width: geometry.size.width * (1 - panelSplitRatio) - AppTheme.dividerWidth / 2)
                    .onTapGesture { appState.activePanel = .right }
                }
            }

            // Bottom function key toolbar
            BottomToolbar(fileOps: fileOps, activePanel: activePanel, otherPanel: otherPanel)
        }
        .background(AppTheme.panelBackground)
        .sheet(isPresented: $fileOps.isShowingDialog) {
            FileOperationDialog(
                fileOps: fileOps,
                activePanel: activePanel,
                otherPanel: otherPanel
            )
        }
        .sheet(isPresented: $appState.showBookmarks) {
            BookmarksSheet(
                onNavigate: { path in
                    Task { await activePanel.navigate(to: path) }
                }
            )
        }
        .onAppear {
            Task {
                await leftPanel.loadDirectory(showHidden: appState.showHiddenFiles)
                await rightPanel.loadDirectory(showHidden: appState.showHiddenFiles)
            }
            fKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else { return event }
                switch event.keyCode {
                case 99: // F3 - View
                    if let item = activePanel.selectedOrCursorItems.first, !item.isDirectory {
                        NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                    }
                    return nil
                case 118: // F4 - Edit
                    if let item = activePanel.selectedOrCursorItems.first, !item.isDirectory {
                        NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                    }
                    return nil
                case 96: // F5 - Copy
                    let items = activePanel.selectedOrCursorItems
                    if !items.isEmpty {
                        fileOps.promptCopy(items: items, destination: otherPanel.currentPath)
                    }
                    return nil
                case 97: // F6 - Move
                    let items = activePanel.selectedOrCursorItems
                    if !items.isEmpty {
                        fileOps.promptMove(items: items, destination: otherPanel.currentPath)
                    }
                    return nil
                case 98: // F7 - Mkdir
                    fileOps.promptMkdir(currentPath: activePanel.currentPath)
                    return nil
                case 100: // F8 - Delete
                    let items = activePanel.selectedOrCursorItems
                    if !items.isEmpty {
                        fileOps.promptDelete(items: items)
                    }
                    return nil
                default:
                    return event
                }
            }
        }
        .onDisappear {
            if let monitor = fKeyMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        .onChange(of: appState.showHiddenFiles) { _, newValue in
            Task {
                await leftPanel.loadDirectory(showHidden: newValue)
                await rightPanel.loadDirectory(showHidden: newValue)
            }
        }
        .focusable()
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    private var activePanel: PanelViewModel {
        appState.activePanel == .left ? leftPanel : rightPanel
    }

    private var otherPanel: PanelViewModel {
        appState.activePanel == .left ? rightPanel : leftPanel
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let hasCmd = keyPress.modifiers.contains(.command)
        let hasShift = keyPress.modifiers.contains(.shift)
        let hasCtrl = keyPress.modifiers.contains(.control)

        switch keyPress.key {
        // Tab = switch panels
        case .tab where !hasCmd && !hasShift && !hasCtrl:
            appState.activePanel = appState.activePanel == .left ? .right : .left
            return .handled

        // Ctrl+Tab = next tab
        case .tab where hasCtrl && !hasShift:
            activePanel.nextTab()
            return .handled

        // Ctrl+Shift+Tab = previous tab
        case .tab where hasCtrl && hasShift:
            activePanel.previousTab()
            return .handled

        // Arrow up/down = move cursor
        case .upArrow:
            activePanel.moveCursor(direction: -1)
            return .handled
        case .downArrow:
            activePanel.moveCursor(direction: 1)
            return .handled

        // Enter = enter directory or open file
        case .return:
            if let cursor = activePanel.cursorItem,
               let item = activePanel.filteredItems.first(where: { $0.id == cursor }) {
                Task { await activePanel.enterDirectory(item) }
            }
            return .handled

        // Backspace = go up
        case .delete:
            Task { await activePanel.goUp() }
            return .handled

        // Space = toggle selection + move down
        case KeyEquivalent(" ") where !hasCmd:
            if let cursor = activePanel.cursorItem {
                activePanel.toggleSelection(cursor)
                activePanel.moveCursor(direction: 1)
            }
            return .handled

        // Cmd+T = new tab
        case KeyEquivalent("t") where hasCmd && !hasShift:
            activePanel.addTab()
            return .handled

        // Cmd+W = close tab
        case KeyEquivalent("w") where hasCmd:
            if let tabId = activePanel.activeTabId {
                activePanel.closeTab(tabId)
            }
            return .handled

        // Cmd+D = duplicate tab
        case KeyEquivalent("d") where hasCmd && !hasShift:
            activePanel.duplicateTab()
            return .handled

        // Cmd+Shift+D = add bookmark
        case KeyEquivalent("d") where hasCmd && hasShift:
            let name = (activePanel.currentPath as NSString).lastPathComponent
            appState.addBookmark(name: name, path: activePanel.currentPath)
            return .handled

        // Cmd+B = show bookmarks
        case KeyEquivalent("b") where hasCmd:
            appState.showBookmarks.toggle()
            return .handled

        // Cmd+. = toggle hidden files
        case KeyEquivalent(".") where hasCmd:
            appState.showHiddenFiles.toggle()
            return .handled

        // Cmd+U = swap panels
        case KeyEquivalent("u") where hasCmd:
            let leftPath = leftPanel.currentPath
            let rightPath = rightPanel.currentPath
            Task {
                await leftPanel.navigate(to: rightPath)
                await rightPanel.navigate(to: leftPath)
            }
            return .handled

        // Cmd+A = select all
        case KeyEquivalent("a") where hasCmd:
            activePanel.selectAll()
            return .handled

        // Cmd+[ = go back
        case KeyEquivalent("[") where hasCmd:
            Task { await activePanel.goBack() }
            return .handled

        // Cmd+] = go forward
        case KeyEquivalent("]") where hasCmd:
            Task { await activePanel.goForward() }
            return .handled

        // Cmd+F = quick search
        case KeyEquivalent("f") where hasCmd:
            activePanel.isQuickSearchActive.toggle()
            if !activePanel.isQuickSearchActive {
                activePanel.quickSearchText = ""
                activePanel.applyQuickSearch()
            }
            return .handled

        default:
            return .ignored
        }
    }
}

// MARK: - Cursor extension for NSCursor
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
