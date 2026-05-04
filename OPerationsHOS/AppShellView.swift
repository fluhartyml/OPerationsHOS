import SwiftUI

struct AppShellView: View {
    @State private var store = OperatorStore()
    @State private var showingNewRecord = false

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
