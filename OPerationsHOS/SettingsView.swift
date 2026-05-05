import SwiftUI

struct SettingsView: View {
    let store: OperatorStore?

    @State private var apiKey: String = ""
    @State private var savedConfirmation: Bool = false
    @State private var showingExport: Bool = false

    init(store: OperatorStore? = nil) {
        self.store = store
    }

    var body: some View {
        Form {
            if let store {
                Section {
                    Button {
                        showingExport = true
                    } label: {
                        Label("Export records", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Save your records as Markdown, CSV, JSON, PDF, or a complete ZIP bundle.")
                }
                .sheet(isPresented: $showingExport) {
                    ExportSheet(store: store)
                }
            }
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
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About OPerationsHOS", systemImage: "info.circle")
                }
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
