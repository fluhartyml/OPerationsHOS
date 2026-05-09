import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity surface for an OPerationsHOS Timer record. Phase 22 wires AlarmKit
/// to register the system alarm; this Live Activity is the in-progress UI on Lock
/// Screen + Dynamic Island. Phase 24b will wire the timer state from the main app.
struct OperationsTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endDate: Date
        var label: String
    }

    var timerName: String
}

struct OPerationsHOSWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OperationsTimerAttributes.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.tint)
                    Text(context.attributes.timerName)
                        .font(.headline)
                    Spacer()
                }
                Text(context.state.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(context.state.endDate, style: .timer)
                    .font(.title.monospacedDigit())
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endDate, style: .timer)
                        .font(.title2.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.timerName)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

extension OperationsTimerAttributes {
    fileprivate static var preview: OperationsTimerAttributes {
        OperationsTimerAttributes(timerName: "Pomodoro")
    }
}

extension OperationsTimerAttributes.ContentState {
    fileprivate static var sample: OperationsTimerAttributes.ContentState {
        OperationsTimerAttributes.ContentState(
            endDate: Date().addingTimeInterval(25 * 60),
            label: "25 minutes — Phase 22 timer"
        )
    }
}

#Preview("Timer Live Activity", as: .content, using: OperationsTimerAttributes.preview) {
    OPerationsHOSWidgetsLiveActivity()
} contentStates: {
    OperationsTimerAttributes.ContentState.sample
}
