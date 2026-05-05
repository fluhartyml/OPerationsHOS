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

    // MARK: - Section semantics
    //
    // Pin = "show on dashboard."
    // Date = "show on date sections regardless of pin."
    // Sparse rule = if a typed section has fewer than 2 pinned records,
    //               include the unpinned ones too so the section isn't empty/lonely.
    // Inbox = unpinned, undated, not surfaced anywhere else.

    private static let typedSectionTypes: Set<ItemType> = [.appliance, .homeSystem, .person, .project]

    private func typedSection(of types: Set<ItemType>) -> [OperatorItem] {
        let inScope = items.filter { !$0.archived && types.contains($0.type) }
        let pinned = inScope.filter { $0.pinned }
        return pinned.count < 2 ? inScope : pinned
    }

    var today: [OperatorItem] {
        let cal = Calendar.current
        return items.filter { item in
            guard !item.archived else { return false }
            guard let due = item.dueDate else { return false }
            return cal.isDateInToday(due) || due < Date()
        }
    }

    /// Top-level Pinned section: pinned records whose type doesn't have its own typed section.
    var topLevelPinned: [OperatorItem] {
        items.filter {
            $0.pinned && !$0.archived && !Self.typedSectionTypes.contains($0.type)
        }
    }

    var homeSystems: [OperatorItem] {
        typedSection(of: [.appliance, .homeSystem])
    }

    var people: [OperatorItem] {
        typedSection(of: [.person])
    }

    var projects: [OperatorItem] {
        typedSection(of: [.project])
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

    var recentlyUpdated: [OperatorItem] {
        items
            .filter { !$0.archived }
            .sorted { $0.updatedDate > $1.updatedDate }
            .prefix(5)
            .map { $0 }
    }

    /// Inbox: orphans — unpinned, undated, and not surfaced in any typed/pinned section.
    var inbox: [OperatorItem] {
        let surfaced: Set<UUID> = Set(
            homeSystems.map { $0.id }
            + people.map { $0.id }
            + projects.map { $0.id }
            + topLevelPinned.map { $0.id }
        )
        return items.filter { item in
            guard !item.archived else { return false }
            guard !item.pinned else { return false }
            guard item.dueDate == nil else { return false }
            return !surfaced.contains(item.id)
        }
    }
}
