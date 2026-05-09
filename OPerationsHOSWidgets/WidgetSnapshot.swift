import Foundation

/// Snapshot of OPerationsHOS dashboard data shared from the main app to the widget.
/// Currently reads from a JSON file inside the App Group container.
/// Phase 24a ships this as the read side; main-app publisher writes it.
struct WidgetSnapshot: Codable {
    struct Row: Codable, Identifiable {
        let id: UUID
        let title: String
        let symbol: String
    }

    let today: [Row]
    let pinned: [Row]
    let inbox: [Row]
    var isPlaceholder: Bool = false

    private enum CodingKeys: String, CodingKey {
        case today, pinned, inbox
    }

    static let empty = WidgetSnapshot(today: [], pinned: [], inbox: [])

    static let placeholder: WidgetSnapshot = {
        var snap = WidgetSnapshot(
            today: [Row(id: UUID(), title: "Sample task due today", symbol: "checklist")],
            pinned: [Row(id: UUID(), title: "Sample pinned record", symbol: "pin.fill")],
            inbox: [Row(id: UUID(), title: "Sample unfiled note", symbol: "tray")]
        )
        snap.isPlaceholder = true
        return snap
    }()

    /// App Group identifier shared between the main app and widget.
    /// Pending: enabling App Groups in Xcode → Capabilities for both targets (Phase 24b).
    static let appGroup = "group.com.ChatGPT.OPerationsHOS"

    static func snapshotURL() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            return nil
        }
        return container.appendingPathComponent("widget-snapshot.json")
    }

    static func read() -> WidgetSnapshot? {
        guard let url = snapshotURL(), FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        } catch {
            return nil
        }
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let url = snapshotURL() else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Silent — widget falls back to .empty if read fails.
        }
    }
}
