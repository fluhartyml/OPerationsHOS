import SwiftUI
import Combine

struct TimerSectionView: View {
    let item: OperatorItem
    let store: OperatorStore

    @State private var tick = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsed: TimeInterval {
        var total = item.accumulatedSeconds
        if let started = item.runningSince {
            total += tick.timeIntervalSince(started)
        }
        return total
    }

    private var formatted: String {
        let total = Int(elapsed)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    private var isRunning: Bool {
        item.runningSince != nil
    }

    private var linkedProject: OperatorItem? {
        guard let id = item.linkedRecordID else { return nil }
        return store.items.first(where: { $0.id == id && $0.type == .project })
    }

    private var allProjects: [OperatorItem] {
        store.items
            .filter { !$0.archived && $0.type == .project }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer").font(.headline)

            HStack {
                Text(formatted)
                    .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                    .foregroundStyle(isRunning ? Color.accentColor : .primary)
                Spacer()
                if isRunning {
                    Button {
                        store.stopTimer(id: item.id)
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button {
                        store.startTimer(id: item.id)
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if !isRunning && item.accumulatedSeconds > 0 {
                Button(role: .destructive) {
                    store.resetTimer(id: item.id)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text("Project").foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("None") {
                        store.linkTimer(item.id, toRecord: nil)
                    }
                    ForEach(allProjects) { project in
                        Button(project.title) {
                            store.linkTimer(item.id, toRecord: project.id)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(linkedProject?.title ?? "Link…")
                            .foregroundStyle(linkedProject == nil ? Color.secondary : Color.accentColor)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .onReceive(timer) { now in
            if isRunning {
                tick = now
            }
        }
    }
}
