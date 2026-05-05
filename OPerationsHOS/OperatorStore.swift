import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class OperatorStore {
    @ObservationIgnored private let modelContext: ModelContext
    var items: [OperatorItem]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.items = []
        refresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<OperatorItem>(
            sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
        )
        do {
            self.items = try modelContext.fetch(descriptor)
        } catch {
            self.items = []
        }
    }

    // MARK: - Lookup

    func item(id: UUID) -> OperatorItem? {
        items.first(where: { $0.id == id })
    }

    // MARK: - CRUD

    func add(_ item: OperatorItem) {
        modelContext.insert(item)
        log(.created, on: item, details: item.title)
        try? modelContext.save()
        refresh()
    }

    func update(_ updated: OperatorItem) {
        updated.updatedDate = Date()
        log(.edited, on: updated, details: updated.title)
        try? modelContext.save()
        refresh()
    }

    func delete(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        modelContext.delete(target)
        try? modelContext.save()
        refresh()
    }

    func togglePin(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        target.pinned.toggle()
        target.updatedDate = Date()
        log(target.pinned ? .pinned : .unpinned, on: target)
        try? modelContext.save()
        refresh()
    }

    func toggleArchive(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        target.archived.toggle()
        target.updatedDate = Date()
        log(target.archived ? .archived : .unarchived, on: target)
        try? modelContext.save()
        refresh()
    }

    private func log(_ kind: ActivityKind, on item: OperatorItem, details: String = "") {
        let event = ActivityEvent(kind: kind, details: details)
        modelContext.insert(event)
        event.owner = item
        if item.events == nil {
            item.events = [event]
        } else {
            item.events?.append(event)
        }
    }

    // MARK: - Attachments

    func attach(_ attachment: Attachment, to item: OperatorItem) {
        modelContext.insert(attachment)
        attachment.owner = item
        if item.attachments == nil {
            item.attachments = [attachment]
        } else {
            item.attachments?.append(attachment)
        }
        item.updatedDate = Date()
        log(.attachmentAdded, on: item, details: attachment.originalName)
        try? modelContext.save()
        refresh()
    }

    func deleteAttachment(_ attachment: Attachment) {
        if let owner = attachment.owner {
            owner.attachments?.removeAll { $0.id == attachment.id }
            owner.updatedDate = Date()
            log(.attachmentRemoved, on: owner, details: attachment.originalName)
        }
        modelContext.delete(attachment)
        try? modelContext.save()
        refresh()
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

    /// Records due strictly today (not overdue).
    var scheduleToday: [OperatorItem] {
        let cal = Calendar.current
        return items.filter { item in
            guard !item.archived else { return false }
            guard let due = item.dueDate else { return false }
            return cal.isDateInToday(due)
        }
        .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }

    /// Records whose due date has passed.
    var expired: [OperatorItem] {
        let cal = Calendar.current
        return items.filter { item in
            guard !item.archived else { return false }
            guard item.status != .complete else { return false }
            guard let due = item.dueDate else { return false }
            return due < Date() && !cal.isDateInToday(due)
        }
        .sorted { ($0.dueDate ?? .distantPast) > ($1.dueDate ?? .distantPast) }
    }

    /// Records with status == .waiting (regardless of date).
    var waiting: [OperatorItem] {
        items.filter { !$0.archived && $0.status == .waiting }
            .sorted { $0.updatedDate > $1.updatedDate }
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
