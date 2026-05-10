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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(modelContext: ModelContext) {
        _store = State(initialValue: OperatorStore(modelContext: modelContext))
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            IPadShellView(store: store)
        } else {
            RootTabView(store: store)
        }
    }
}
