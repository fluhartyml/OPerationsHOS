import Foundation
import SwiftData

@Model
final class ActivityEvent {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var kind: ActivityKind = ActivityKind.created
    var details: String = ""
    var owner: OperatorItem?

    init(kind: ActivityKind, details: String = "") {
        self.id = UUID()
        self.timestamp = Date()
        self.kind = kind
        self.details = details
    }
}

enum ActivityKind: String, Codable, CaseIterable {
    case created
    case edited
    case statusChanged
    case priorityChanged
    case pinned
    case unpinned
    case archived
    case unarchived
    case attachmentAdded
    case attachmentRemoved

    var label: String {
        switch self {
        case .created: return "Created"
        case .edited: return "Edited"
        case .statusChanged: return "Status changed"
        case .priorityChanged: return "Priority changed"
        case .pinned: return "Pinned"
        case .unpinned: return "Unpinned"
        case .archived: return "Archived"
        case .unarchived: return "Unarchived"
        case .attachmentAdded: return "Attachment added"
        case .attachmentRemoved: return "Attachment removed"
        }
    }

    var symbol: String {
        switch self {
        case .created: return "plus.circle"
        case .edited: return "pencil"
        case .statusChanged: return "flag"
        case .priorityChanged: return "exclamationmark.triangle"
        case .pinned: return "pin"
        case .unpinned: return "pin.slash"
        case .archived: return "archivebox"
        case .unarchived: return "tray.and.arrow.up"
        case .attachmentAdded: return "paperclip"
        case .attachmentRemoved: return "xmark.bin"
        }
    }
}
