import Foundation
import SwiftUI

enum PanelSide: String, Codable {
    case left, right
}

enum SortField: String, Codable, CaseIterable {
    case name = "Name"
    case size = "Size"
    case date = "Date"
    case ext = "Extension"
}

enum SortOrder: String, Codable {
    case ascending, descending

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

struct ColumnConfig: Codable, Equatable {
    var showExtension: Bool = true
    var showSize: Bool = true
    var showDate: Bool = true
    var showPermissions: Bool = false
    var showOwner: Bool = false
    var nameWidth: CGFloat = 250
    var extWidth: CGFloat = 60
    var sizeWidth: CGFloat = 80
    var dateWidth: CGFloat = 120
    var permissionsWidth: CGFloat = 100
    var ownerWidth: CGFloat = 80
}
