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
        syncToEventKit(item)
        refresh()
    }

    func update(_ updated: OperatorItem) {
        updated.updatedDate = Date()
        log(.edited, on: updated, details: updated.title)
        try? modelContext.save()
        syncToEventKit(updated)
        refresh()
    }

    func delete(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        if let eventID = target.eventIdentifier {
            EventKitStore.shared.deleteEvent(identifier: eventID)
        }
        if let reminderID = target.reminderIdentifier {
            EventKitStore.shared.deleteReminder(identifier: reminderID)
        }
        modelContext.delete(target)
        try? modelContext.save()
        refresh()
    }

    private func syncToEventKit(_ item: OperatorItem) {
        // Calendar sync: any record with a dueDate
        if item.dueDate != nil && EventKitStore.shared.calendarsAuthorized {
            if let id = EventKitStore.shared.upsertEvent(for: item) {
                item.eventIdentifier = id
                try? modelContext.save()
            }
        } else if item.dueDate == nil, let oldID = item.eventIdentifier {
            EventKitStore.shared.deleteEvent(identifier: oldID)
            item.eventIdentifier = nil
            try? modelContext.save()
        }

        // Reminders sync: task-type records
        if item.type == .task && EventKitStore.shared.remindersAuthorized {
            if let id = EventKitStore.shared.upsertReminder(for: item) {
                item.reminderIdentifier = id
                try? modelContext.save()
            }
        }
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

    // MARK: - Timers

    func startTimer(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        guard target.type == .timer else { return }
        if target.runningSince == nil {
            target.runningSince = Date()
            target.updatedDate = Date()
            try? modelContext.save()

            // Schedule a system-level AlarmKit countdown if the timer has a target duration
            if let duration = target.alarmTargetSeconds, duration > 0 {
                Task { @MainActor in
                    if let alarmID = await AlarmKitManager.shared.scheduleTimer(for: target, duration: duration) {
                        target.alarmIdentifier = alarmID.uuidString
                        try? self.modelContext.save()
                        self.refresh()
                    }
                }
            }
            refresh()
        }
    }

    func stopTimer(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        guard target.type == .timer else { return }
        if let started = target.runningSince {
            target.accumulatedSeconds += Date().timeIntervalSince(started)
            target.runningSince = nil
            target.updatedDate = Date()

            // Cancel any system-level AlarmKit countdown tied to this timer
            if let alarmIDString = target.alarmIdentifier,
               let alarmID = UUID(uuidString: alarmIDString) {
                AlarmKitManager.shared.cancelTimer(id: alarmID)
                target.alarmIdentifier = nil
            }

            try? modelContext.save()
            refresh()
        }
    }

    func resetTimer(id: UUID) {
        guard let target = items.first(where: { $0.id == id }) else { return }
        guard target.type == .timer else { return }
        target.accumulatedSeconds = 0
        target.runningSince = nil
        target.updatedDate = Date()
        try? modelContext.save()
        refresh()
    }

    func linkTimer(_ timerID: UUID, toRecord recordID: UUID?) {
        guard let target = items.first(where: { $0.id == timerID }) else { return }
        target.linkedRecordID = recordID
        target.updatedDate = Date()
        try? modelContext.save()
        refresh()
    }

    // MARK: - Sample data

    /// Adds any missing sample records back into the store.
    /// Re-running is safe — existing samples are skipped, deleted ones are restored.
    func populateSampleRecords() {
        let existingIDs = Set(items.map { $0.id })
        for sample in SampleData.allSamples() {
            if !existingIDs.contains(sample.id) {
                modelContext.insert(sample)
                log(.created, on: sample, details: sample.title)
            }
        }
        try? modelContext.save()
        refresh()
    }

    func runningTimers() -> [OperatorItem] {
        items.filter { $0.type == .timer && $0.runningSince != nil && !$0.archived }
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
