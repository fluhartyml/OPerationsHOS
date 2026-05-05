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

    init(modelContext: ModelContext) {
        _store = State(initialValue: OperatorStore(modelContext: modelContext))
    }

    var body: some View {
        RootTabView(store: store)
    }
}
