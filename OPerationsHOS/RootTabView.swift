import SwiftUI

struct RootTabView: View {
    let store: OperatorStore

    @State private var dashboardSheet = false
    @State private var scheduleSheet = false
    @State private var vaultSheet = false
    @State private var systemsSheet = false
    @State private var maintenanceSheet = false
    @State private var projectsSheet = false
    @State private var peopleSheet = false
    @State private var timersSheet = false
    @State private var mediaSheet = false
    @State private var propertySheet = false

    var body: some View {
        TabView {
            tab("Dashboard", "rectangle.grid.2x2", sheet: $dashboardSheet) {
                DashboardView(store: store, showingNewRecord: $dashboardSheet)
            }

            tab("Schedule", "calendar", sheet: $scheduleSheet) {
                ScheduleView(store: store, showingNewRecord: $scheduleSheet)
            }

            tab("Vault", "tray.full", sheet: $vaultSheet) {
                ModuleView(
                    title: "Vault",
                    symbol: "tray.full",
                    scope: .all,
                    store: store,
                    showingNewRecord: $vaultSheet
                )
            }

            tab("Systems", "house", sheet: $systemsSheet) {
                ModuleView(
                    title: "Systems",
                    symbol: "house",
                    scope: .types([.homeSystem, .appliance]),
                    store: store,
                    showingNewRecord: $systemsSheet
                )
            }

            tab("Maintenance", "wrench.and.screwdriver", sheet: $maintenanceSheet) {
                ModuleView(
                    title: "Maintenance",
                    symbol: "wrench.and.screwdriver",
                    scope: .types([.maintenance]),
                    store: store,
                    showingNewRecord: $maintenanceSheet
                )
            }

            tab("Projects", "square.stack.3d.up", sheet: $projectsSheet) {
                ModuleView(
                    title: "Projects",
                    symbol: "square.stack.3d.up",
                    scope: .types([.project]),
                    store: store,
                    showingNewRecord: $projectsSheet
                )
            }

            tab("People", "person.crop.circle", sheet: $peopleSheet) {
                ModuleView(
                    title: "People",
                    symbol: "person.crop.circle",
                    scope: .types([.person]),
                    store: store,
                    showingNewRecord: $peopleSheet
                )
            }

            tab("Timers", "timer", sheet: $timersSheet) {
                ModuleView(
                    title: "Timers",
                    symbol: "timer",
                    scope: .types([.timer]),
                    store: store,
                    showingNewRecord: $timersSheet
                )
            }

            tab("Media", "photo", sheet: $mediaSheet) {
                ModuleView(
                    title: "Media",
                    symbol: "photo",
                    scope: .types([.media]),
                    store: store,
                    showingNewRecord: $mediaSheet
                )
            }

            tab("Property", "building.2", sheet: $propertySheet) {
                ModuleView(
                    title: "Property",
                    symbol: "building.2",
                    scope: .types([.property]),
                    store: store,
                    showingNewRecord: $propertySheet
                )
            }
        }
    }

    @ViewBuilder
    private func tab<Content: View>(
        _ title: String,
        _ symbol: String,
        sheet: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .navigationDestination(for: UUID.self) { id in
                    RecordDetailView(id: id, store: store)
                }
        }
        .tabItem {
            Label(title, systemImage: symbol)
        }
        .sheet(isPresented: sheet) {
            RecordEditSheet(mode: .new, store: store)
        }
    }
}
