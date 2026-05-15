import SwiftUI

/// One-time welcome sheet shown on the first launch after install. After the user
/// completes either path (Take a tour / Start fresh), the `hasShownWelcome` flag
/// is set in UserDefaults so this never re-fires. Permissions stay just-in-time
/// per iOS convention — no permission gauntlet here.
struct OnboardingSheet: View {
    let onTour: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                Text("Welcome to OPerationsHOS")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Where the moving parts of your life — records, schedules, people, and projects — become retrievable and structured.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onTour()
                } label: {
                    Text("Take a Tour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Populates a small set of sample records so you can see how the app works. Sample records are easy to delete or replace later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    onStart()
                } label: {
                    Text("Start Fresh")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(32)
        .frame(maxWidth: 480)
    }
}
