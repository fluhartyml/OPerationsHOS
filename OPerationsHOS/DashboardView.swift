import SwiftUI

struct DashboardView: View {
    let store: OperatorStore
    @Binding var showingNewRecord: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                section("Today", items: store.today)
                section("Pinned", items: store.pinned)
                section("Home Systems", items: store.homeSystems)
                section("People", items: store.people)
                section("Upcoming", items: store.upcoming)
                section("Projects", items: store.projects)
                section("Recently Updated", items: store.recentlyUpdated)
            }
            .padding()
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
