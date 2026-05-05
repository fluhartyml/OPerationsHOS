import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var savedConfirmation: Bool = false

    var body: some View {
        Form {
            Section {
                SecureField("Anthropic API Key", text: $apiKey)
                    .autocorrectionDisabled()
                HStack {
                    Button("Save") {
                        save()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                    Spacer()
                    if KeychainStorage.read(.anthropicAPIKey) != nil {
                        Button(role: .destructive) {
                            clear()
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
                if savedConfirmation {
                    Label("Saved to Keychain", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } header: {
                Text("Anthropic API")
            } footer: {
                Text("AI actions (Summarize, Extract Dates, Suggest Category) call the Anthropic API directly using your key. Keys are stored in the iOS Keychain and never leave the device except as the Authorization header on requests to api.anthropic.com.")
            }

            Section("About") {
                LabeledContent("App", value: "OPerationsHOS")
                LabeledContent("Tagline", value: "Organize. Track. Operate.")
                LabeledContent("Privacy", value: "fluharty.me/privacy")
                LabeledContent("Support", value: "github.com/fluhartyml/OPerationsHOS")
            }
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            apiKey = KeychainStorage.read(.anthropicAPIKey) ?? ""
        }
    }

    private func save() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        KeychainStorage.write(.anthropicAPIKey, value: trimmed)
        savedConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedConfirmation = false
        }
    }

    private func clear() {
        KeychainStorage.delete(.anthropicAPIKey)
        apiKey = ""
        savedConfirmation = false
    }
}
