import SwiftUI

struct ScheduleView: View {
    let store: OperatorStore
    @Binding var showingNewRecord: Bool

    var body: some View {
        Group {
            if isEmpty {
                empty
            } else {
                list
            }
        }
        .navigationTitle("Schedule")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewRecord = true } label: {
                    Label("New Record", systemImage: "plus")
                }
            }
        }
    }

    private var isEmpty: Bool {
        store.expired.isEmpty
            && store.scheduleToday.isEmpty
            && store.upcoming.isEmpty
            && store.waiting.isEmpty
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                section("Expired", systemImage: "exclamationmark.triangle.fill", items: store.expired)
                section("Today", systemImage: "sun.max.fill", items: store.scheduleToday)
                section("Upcoming", systemImage: "calendar", items: store.upcoming)
                section("Waiting", systemImage: "hourglass", items: store.waiting)
            }
            .padding()
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label("Nothing scheduled", systemImage: "calendar")
        } description: {
            Text("Records with a due date or marked Waiting will appear here.")
        } actions: {
            Button {
                showingNewRecord = true
            } label: {
                Label("New Record", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func section(_ title: String, systemImage: String, items: [OperatorItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .foregroundStyle(.tint)
                    Text(title).font(.title3.weight(.semibold))
                    Text("\(items.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.leading, 4)
                ForEach(items) { item in
                    NavigationLink(value: item.id) {
                        OperatorCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
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
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
