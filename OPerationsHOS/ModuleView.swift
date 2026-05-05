import SwiftUI

struct ModuleView: View {
    let title: String
    let symbol: String
    let scope: ModuleScope
    let store: OperatorStore
    @Binding var showingNewRecord: Bool

    var items: [OperatorItem] {
        let live = store.items.filter { !$0.archived }
        let scoped: [OperatorItem]
        switch scope {
        case .all:
            scoped = live
        case .types(let allowed):
            scoped = live.filter { allowed.contains($0.type) }
        }
        return scoped.sorted { $0.updatedDate > $1.updatedDate }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                empty
            } else {
                list
            }
        }
        .navigationTitle(title)
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

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
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
            .padding()
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label("Nothing in \(title) yet", systemImage: symbol)
        } description: {
            Text(emptyMessage)
        } actions: {
            Button {
                showingNewRecord = true
            } label: {
                Label("New Record", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyMessage: String {
        switch scope {
        case .all:
            return "Every record you create lands here. Tap the plus button to start."
        case .types:
            return "Records you mark as \(title.lowercased()) appear here."
        }
    }
}

enum ModuleScope: Equatable {
    case all
    case types(Set<ItemType>)
}
