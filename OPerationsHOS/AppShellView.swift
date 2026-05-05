import SwiftUI
import SwiftData

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        AppShellInner(modelContext: modelContext)
    }
}

private struct AppShellInner: View {
    @State private var store: OperatorStore
    @State private var showingNewRecord = false

    init(modelContext: ModelContext) {
        _store = State(initialValue: OperatorStore(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            DashboardView(store: store, showingNewRecord: $showingNewRecord)
                .navigationDestination(for: UUID.self) { id in
                    RecordDetailView(id: id, store: store)
                }
        }
        .sheet(isPresented: $showingNewRecord) {
            RecordEditSheet(mode: .new, store: store)
        }
    }
}
