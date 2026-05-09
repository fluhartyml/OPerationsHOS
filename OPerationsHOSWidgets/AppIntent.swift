import WidgetKit
import AppIntents

enum WidgetView: String, AppEnum {
    case today
    case pinned
    case inbox

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Widget View")
    }

    static var caseDisplayRepresentations: [WidgetView: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today"),
            .pinned: DisplayRepresentation(title: "Pinned"),
            .inbox: DisplayRepresentation(title: "Inbox"),
        ]
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "OPerationsHOS Widget" }
    static var description: IntentDescription { IntentDescription("Pick which slice of OPerationsHOS the widget surfaces.") }

    @Parameter(title: "Show", default: .today)
    var view: WidgetView
}
