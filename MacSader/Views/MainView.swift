import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var leftPanel = PanelViewModel(side: .left)
    @StateObject private var rightPanel = PanelViewModel(side: .right)
    @StateObject private var fileOps = FileOperationViewModel()

    @State private var panelSplitRatio: CGFloat = 0.5
    @State private var isDraggingDivider = false
    @State private var fKeyMonitor: Any?
    @State private var showSelectPattern = false
    @State private var showDeselectPattern = false
    @State private var selectPattern = ""

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left panel
                    PanelView(
                        viewModel: leftPanel,
                        isActive: appState.activePanel == .left,
                        fileOps: fileOps,
                        otherPanelPath: rightPanel.currentPath
                    )
                    .frame(width: leftPanelWidth(in: geometry))
                    .onTapGesture { appState.activePanel = .left }

                    // Divider
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
                                .onEnded { _ in isDraggingDivider = false }
                        )

                    // Right panel
                    PanelView(
                        viewModel: rightPanel,
                        isActive: appState.activePanel == .right,
                        fileOps: fileOps,
                        otherPanelPath: leftPanel.currentPath
                    )
                    .frame(width: rightPanelWidth(in: geometry))
                    .onTapGesture { appState.activePanel = .right }

                    // Quick Look preview (optional)
                    if appState.showPreview {
                        Divider()
                        PreviewPanel(item: previewItem)
                            .frame(width: min(300, geometry.size.width * 0.25))
                    }
                }
            }

            // Bottom toolbar
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
        .sheet(isPresented: $showSelectPattern) {
            SelectByPatternDialog(
                isPresented: $showSelectPattern,
                pattern: $selectPattern,
                isDeselect: false,
                onConfirm: { pattern in activePanel.selectByPattern(pattern) }
            )
        }
        .sheet(isPresented: $showDeselectPattern) {
            SelectByPatternDialog(
                isPresented: $showDeselectPattern,
                pattern: $selectPattern,
                isDeselect: true,
                onConfirm: { pattern in activePanel.deselectByPattern(pattern) }
            )
        }
        .onAppear {
            Task {
                await leftPanel.loadDirectory(showHidden: appState.showHiddenFiles)
                await rightPanel.loadDirectory(showHidden: appState.showHiddenFiles)
            }
            setupFKeyMonitor()
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

    // MARK: - Layout

    private func leftPanelWidth(in geometry: GeometryProxy) -> CGFloat {
        let previewWidth: CGFloat = appState.showPreview ? min(300, geometry.size.width * 0.25) + 1 : 0
        return (geometry.size.width - previewWidth) * panelSplitRatio - AppTheme.dividerWidth / 2
    }

    private func rightPanelWidth(in geometry: GeometryProxy) -> CGFloat {
        let previewWidth: CGFloat = appState.showPreview ? min(300, geometry.size.width * 0.25) + 1 : 0
        return (geometry.size.width - previewWidth) * (1 - panelSplitRatio) - AppTheme.dividerWidth / 2
    }

    // MARK: - State

    private var activePanel: PanelViewModel {
        appState.activePanel == .left ? leftPanel : rightPanel
    }

    private var otherPanel: PanelViewModel {
        appState.activePanel == .left ? rightPanel : leftPanel
    }

    private var previewItem: FileItem? {
        guard let cursor = activePanel.cursorItem else { return nil }
        return activePanel.filteredItems.first { $0.id == cursor }
    }

    // MARK: - F-Key Monitor

    private func setupFKeyMonitor() {
        fKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let noModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
            switch event.keyCode {
            case 120 where noModifiers: // F2 - Rename
                activePanel.startRename()
                return nil
            case 99 where noModifiers: // F3 - View / Quick Look
                triggerQuickLook()
                return nil
            case 118 where noModifiers: // F4 - Edit
                if let item = activePanel.selectedOrCursorItems.first, !item.isDirectory {
                    NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                }
                return nil
            case 96 where noModifiers: // F5 - Copy
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptCopy(items: items, destination: otherPanel.currentPath)
                }
                return nil
            case 97 where noModifiers: // F6 - Move
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptMove(items: items, destination: otherPanel.currentPath)
                }
                return nil
            case 98 where noModifiers: // F7 - Mkdir
                fileOps.promptMkdir(currentPath: activePanel.currentPath)
                return nil
            case 100 where noModifiers: // F8 - Delete
                let items = activePanel.selectedOrCursorItems
                if !items.isEmpty {
                    fileOps.promptDelete(items: items)
                }
                return nil
            case 101 where noModifiers: // F9 - Terminal
                openTerminal(at: activePanel.currentPath)
                return nil
            default:
                return event
            }
        }
    }

    private func triggerQuickLook() {
        guard let item = activePanel.selectedOrCursorItems.first, !item.isDirectory else { return }
        let url = URL(fileURLWithPath: item.path) as NSURL
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
        } else if let panel = QLPreviewPanel.shared() {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func openTerminal(at path: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd \(path.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    // MARK: - Keyboard Handler

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let hasCmd = keyPress.modifiers.contains(.command)
        let hasShift = keyPress.modifiers.contains(.shift)
        let hasCtrl = keyPress.modifiers.contains(.control)
        let hasOpt = keyPress.modifiers.contains(.option)

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
        case .upArrow where !hasCmd && !hasOpt:
            if hasShift {
                // Shift+Up = select + move
                if let cursor = activePanel.cursorItem { activePanel.toggleSelection(cursor) }
                activePanel.moveCursor(direction: -1)
            } else {
                activePanel.moveCursor(direction: -1)
            }
            return .handled

        case .downArrow where !hasCmd && !hasOpt:
            if hasShift {
                if let cursor = activePanel.cursorItem { activePanel.toggleSelection(cursor) }
                activePanel.moveCursor(direction: 1)
            } else {
                activePanel.moveCursor(direction: 1)
            }
            return .handled

        // Cmd+Up = go up directory
        case .upArrow where hasCmd:
            Task { await activePanel.goUp() }
            return .handled

        // Page Up/Down
        case .pageUp:
            activePanel.moveCursorPage(direction: -1, pageSize: 20)
            return .handled

        case .pageDown:
            activePanel.moveCursorPage(direction: 1, pageSize: 20)
            return .handled

        // Home/End
        case .home:
            activePanel.moveCursorToEnd(toTop: true)
            return .handled

        case .end:
            activePanel.moveCursorToEnd(toTop: false)
            return .handled

        // Enter = enter directory or open file
        case .return:
            if activePanel.renamingItemId != nil {
                Task { await activePanel.commitRename() }
            } else if let cursor = activePanel.cursorItem,
               let item = activePanel.filteredItems.first(where: { $0.id == cursor }) {
                Task { await activePanel.enterDirectory(item) }
            }
            return .handled

        // Escape = cancel rename or quick search
        case .escape:
            if activePanel.renamingItemId != nil {
                activePanel.cancelRename()
            } else if activePanel.isQuickSearchActive {
                activePanel.isQuickSearchActive = false
                activePanel.quickSearchText = ""
                activePanel.applyQuickSearch()
            } else {
                activePanel.selectedItems.removeAll()
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

        // Cmd+P = toggle preview
        case KeyEquivalent("p") where hasCmd:
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.showPreview.toggle()
            }
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

        // Cmd+= = equalize panels
        case KeyEquivalent("=") where hasCmd:
            withAnimation(.easeInOut(duration: 0.2)) {
                panelSplitRatio = 0.5
            }
            return .handled

        // Cmd+Shift+S = sync panels (other panel navigates to active panel's path)
        case KeyEquivalent("s") where hasCmd && hasShift:
            Task { await otherPanel.navigate(to: activePanel.currentPath) }
            return .handled

        // Cmd+A = select all
        case KeyEquivalent("a") where hasCmd:
            activePanel.selectAll()
            return .handled

        // Cmd+Shift+A = deselect all
        case KeyEquivalent("a") where hasCmd && hasShift:
            activePanel.selectedItems.removeAll()
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

        // Cmd+C = copy path to clipboard
        case KeyEquivalent("c") where hasCmd:
            activePanel.copySelectedPathsToClipboard()
            return .handled

        // Cmd+R = refresh
        case KeyEquivalent("r") where hasCmd:
            Task { await activePanel.loadDirectory(showHidden: appState.showHiddenFiles) }
            return .handled

        // Cmd+Shift+= (plus) = select by pattern
        case KeyEquivalent("+") where hasCmd:
            selectPattern = "*."
            showSelectPattern = true
            return .handled

        // Cmd+- = deselect by pattern
        case KeyEquivalent("-") where hasCmd:
            selectPattern = "*."
            showDeselectPattern = true
            return .handled

        // * = invert selection
        case KeyEquivalent("*"):
            activePanel.invertSelection()
            return .handled

        default:
            return .ignored
        }
    }
}

// MARK: - Cursor extension
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

// QLPreviewPanel import
import QuickLookUI
