import SwiftUI

struct TabBarView: View {
    @ObservedObject var viewModel: PanelViewModel
    let isActive: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: tab.id == viewModel.activeTabId,
                        isActive: isActive,
                        onSelect: { viewModel.switchToTab(tab.id) },
                        onClose: { viewModel.closeTab(tab.id) }
                    )
                }

                // New tab button
                Button {
                    viewModel.addTab()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: AppTheme.tabHeight)
                }
                .buttonStyle(.plain)
                .help("New Tab (Cmd+T)")

                Spacer()
            }
        }
        .frame(height: AppTheme.tabHeight)
        .background(AppTheme.tabBarBackground)
    }
}

struct TabItemView: View {
    let tab: PanelTab
    let isSelected: Bool
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            if tab.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            Text(tab.displayTitle)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
                .foregroundColor(isSelected && isActive ? .primary : .secondary)

            if isHovering || isSelected {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Close Tab (Cmd+W)")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: AppTheme.tabHeight)
        .background(
            Group {
                if isSelected {
                    AppTheme.tabActiveBackground
                } else if isHovering {
                    Color(nsColor: .controlBackgroundColor).opacity(0.5)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(alignment: .bottom) {
            if isSelected && isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
    }
}
