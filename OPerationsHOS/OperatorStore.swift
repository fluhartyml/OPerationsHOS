import Foundation
import Observation

@MainActor
@Observable
final class OperatorStore {
    var items: [OperatorItem]

    init(items: [OperatorItem] = PreviewData.sampleItems) {
        self.items = items
    }

    // MARK: - Lookup

    func item(id: UUID) -> OperatorItem? {
        items.first(where: { $0.id == id })
    }

    // MARK: - CRUD

    func add(_ item: OperatorItem) {
        items.append(item)
    }

    func update(_ updated: OperatorItem) {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return }
        var refreshed = updated
        refreshed.updatedDate = Date()
        items[index] = refreshed
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].pinned.toggle()
        items[index].updatedDate = Date()
    }

    func toggleArchive(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].archived.toggle()
        items[index].updatedDate = Date()
    }

    // MARK: - Slices

    var pinned: [OperatorItem] {
        items.filter { $0.pinned && !$0.archived }
    }

    var today: [OperatorItem] {
        let cal = Calendar.current
        return items.filter { item in
            guard !item.archived else { return false }
            guard let due = item.dueDate else { return false }
            return cal.isDateInToday(due) || due < Date()
        }
    }

    var upcoming: [OperatorItem] {
        let now = Date()
        let cal = Calendar.current
        return items
            .filter { !$0.archived }
            .filter { item in
                guard let due = item.dueDate else { return false }
                return due > now && !cal.isDateInToday(due)
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var homeSystems: [OperatorItem] {
        items.filter { !$0.archived && ($0.type == .homeSystem || $0.type == .appliance) }
    }

    var projects: [OperatorItem] {
        items.filter { !$0.archived && $0.type == .project }
    }

    var people: [OperatorItem] {
        items.filter { !$0.archived && $0.type == .person }
    }

    var recentlyUpdated: [OperatorItem] {
        items
            .filter { !$0.archived }
            .sorted { $0.updatedDate > $1.updatedDate }
            .prefix(5)
            .map { $0 }
    }
}
