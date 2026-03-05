import SwiftUI

struct FileRowView: View {
    let item: FileItem
    let isSelected: Bool
    let isCursor: Bool
    let showIcons: Bool
    let columnConfig: ColumnConfig
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            // Name column
            HStack(spacing: 6) {
                if showIcons {
                    Image(systemName: item.icon)
                        .font(.system(size: fontSize - 1))
                        .foregroundColor(AppTheme.colorForFileType(item.iconColor))
                        .frame(width: 16, alignment: .center)
                }

                Text(item.name)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(nameColor)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if item.isSymlink {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                Spacer()
            }
            .frame(minWidth: 100, maxWidth: .infinity)

            // Extension column
            if columnConfig.showExtension {
                Text(item.isDirectory ? "" : item.fileExtension)
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: columnConfig.extWidth, alignment: .leading)
            }

            // Size column
            if columnConfig.showSize {
                Text(item.displaySize)
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundColor(item.isDirectory ? .secondary.opacity(0.5) : .secondary)
                    .frame(width: columnConfig.sizeWidth, alignment: .trailing)
            }

            // Date column
            if columnConfig.showDate {
                Text(item.displayDate)
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: columnConfig.dateWidth, alignment: .trailing)
            }

            // Permissions column
            if columnConfig.showPermissions {
                Text(item.permissions)
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: columnConfig.permissionsWidth, alignment: .leading)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
        .overlay(
            Group {
                if isCursor {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(AppTheme.rowCursorBorder.opacity(0.5), lineWidth: 1)
                }
            }
        )
    }

    private var nameColor: Color {
        if isSelected {
            return .accentColor
        }
        if item.name == ".." {
            return .secondary
        }
        if item.isDirectory {
            return .primary
        }
        if item.isHidden {
            return .secondary.opacity(0.6)
        }
        return .primary
    }
}
