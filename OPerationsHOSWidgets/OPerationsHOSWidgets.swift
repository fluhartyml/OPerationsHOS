import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct OperationsEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let snapshot: WidgetSnapshot
}

// MARK: - Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OperationsEntry {
        OperationsEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            snapshot: .placeholder
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> OperationsEntry {
        OperationsEntry(
            date: .now,
            configuration: configuration,
            snapshot: WidgetSnapshot.read() ?? .placeholder
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<OperationsEntry> {
        let snapshot = WidgetSnapshot.read() ?? .empty
        let entry = OperationsEntry(date: .now, configuration: configuration, snapshot: snapshot)
        // Refresh hourly — main app refresh hooks update sooner via WidgetCenter.shared.reloadAllTimelines()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

// MARK: - Entry view

struct OperationsEntryView: View {
    let entry: OperationsEntry
    @Environment(\.widgetFamily) private var family

    private var rows: [WidgetSnapshot.Row] {
        switch entry.configuration.view {
        case .today:  return entry.snapshot.today
        case .pinned: return entry.snapshot.pinned
        case .inbox:  return entry.snapshot.inbox
        }
    }

    private var sectionTitle: String {
        switch entry.configuration.view {
        case .today:  return "Today"
        case .pinned: return "Pinned"
        case .inbox:  return "Inbox"
        }
    }

    private var sectionSymbol: String {
        switch entry.configuration.view {
        case .today:  return "sun.max"
        case .pinned: return "pin.fill"
        case .inbox:  return "tray"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: sectionSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(sectionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !entry.snapshot.isPlaceholder {
                    Text("\(rows.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if entry.snapshot.isPlaceholder {
                placeholderBody
            } else if rows.isEmpty {
                emptyBody
            } else {
                rowsBody
            }

            Spacer(minLength: 0)
        }
    }

    private var placeholderBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("OPerationsHOS")
                .font(.headline)
            Text("Open the app to start tracking.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nothing in \(sectionTitle).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var rowsBody: some View {
        let visible = Array(rows.prefix(family == .systemSmall ? 2 : 4))
        VStack(alignment: .leading, spacing: 3) {
            ForEach(visible, id: \.id) { row in
                HStack(spacing: 6) {
                    Image(systemName: row.symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(row.title)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            if rows.count > visible.count {
                Text("+\(rows.count - visible.count) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Widget

struct OPerationsHOSWidgets: Widget {
    let kind: String = "OPerationsHOSWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            OperationsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("OPerationsHOS")
        .description("Today, Pinned, or Inbox at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    OPerationsHOSWidgets()
} timeline: {
    OperationsEntry(date: .now, configuration: ConfigurationAppIntent(), snapshot: .placeholder)
    OperationsEntry(date: .now, configuration: ConfigurationAppIntent(), snapshot: .empty)
}
