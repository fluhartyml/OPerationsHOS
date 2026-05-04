import SwiftUI

struct RecordDetailView: View {
    let id: UUID
    let store: OperatorStore

    @State private var showingEdit = false
    @Environment(\.dismiss) private var dismiss

    private var item: OperatorItem? {
        store.item(id: id)
    }

    var body: some View {
        Group {
            if let item {
                content(for: item)
            } else {
                ContentUnavailableView("Record Removed", systemImage: "trash")
            }
        }
        .navigationTitle(item?.title ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let item {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button {
                            store.togglePin(id: item.id)
                        } label: {
                            Label(item.pinned ? "Unpin" : "Pin",
                                  systemImage: item.pinned ? "pin.slash" : "pin")
                        }
                        Button {
                            store.toggleArchive(id: item.id)
                        } label: {
                            Label(item.archived ? "Unarchive" : "Archive",
                                  systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            store.delete(id: item.id)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecordEditSheet(mode: .edit(id), store: store)
        }
    }

    @ViewBuilder
    private func content(for item: OperatorItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                header(for: item)
                metadata(for: item)
                if !item.body.isEmpty {
                    bodySection(for: item)
                }
                if !item.tags.isEmpty {
                    tagsSection(for: item)
                }
                placeholders
            }
            .padding()
        }
    }

    private func header(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: item.type.symbol)
                    .font(.title)
                    .foregroundStyle(.tint)
                Text(item.type.label)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if item.archived {
                    Image(systemName: "archivebox.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(item.title).font(.title2.weight(.semibold))
            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metadata(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Status", item.status.label)
            row("Priority", item.priority.label)
            if let due = item.dueDate {
                row("Due", due.formatted(date: .abbreviated, time: .omitted))
            }
            if let system = item.relatedSystem {
                row("Related System", system)
            }
            row("Created", item.createdDate.formatted(date: .abbreviated, time: .omitted))
            row("Updated", item.updatedDate.formatted(date: .abbreviated, time: .omitted))
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    private func bodySection(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.headline)
            Text(item.body)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func tagsSection(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags").font(.headline)
            HStack(spacing: 6) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.thinMaterial, in: Capsule())
                }
                Spacer()
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var placeholders: some View {
        VStack(alignment: .leading, spacing: 12) {
            placeholder("Attachments", "Will arrive in Phase 9")
            placeholder("Activity Log", "Will arrive in Phase 10")
        }
    }

    private func placeholder(_ title: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
