import SwiftUI

struct DashboardView: View {
    let store: OperatorStore
    @Binding var showingNewRecord: Bool

    var body: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                populatedDashboard
            }
        }
        .navigationTitle("OPerationsHOS")
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

    private var populatedDashboard: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                section("Today", items: store.today)
                section("Pinned", items: store.topLevelPinned)
                section("Home Systems", items: store.homeSystems)
                section("People", items: store.people)
                section("Projects", items: store.projects)
                section("Upcoming", items: store.upcoming)
                section("Recently Updated", items: store.recentlyUpdated)
                section("Inbox", items: store.inbox)
            }
            .padding()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Records Yet", systemImage: "tray")
        } description: {
            Text("Tap the plus button to create your first record. Track warranties, appliances, projects, people, vendors, and receipts.")
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
    private func section(_ title: String, items: [OperatorItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                Text(title)
                    .font(.title3.weight(.semibold))
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
