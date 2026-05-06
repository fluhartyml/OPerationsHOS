import SwiftUI
import LocalAuthentication

struct VaultView: View {
    let store: OperatorStore
    @Binding var showingNewRecord: Bool

    @State private var unlocked: Bool = false
    @State private var authError: String?
    @State private var authenticating: Bool = false

    private var vaultItems: [OperatorItem] {
        store.items
            .filter { !$0.archived && $0.type.isVaultOnly }
            .sorted { $0.updatedDate > $1.updatedDate }
    }

    var body: some View {
        Group {
            if !unlocked {
                lockedGate
            } else if vaultItems.isEmpty {
                emptyVault
            } else {
                vaultList
            }
        }
        .navigationTitle("Vault")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if unlocked {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewRecord = true } label: {
                        Label("New Record", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        unlocked = false
                    } label: {
                        Label("Lock", systemImage: "lock.fill")
                    }
                }
            }
        }
        .onChange(of: showingNewRecord) { _, presenting in
            // Re-lock if user navigates away mid-session
            if !presenting && !unlocked { /* no-op */ }
        }
    }

    // MARK: - Locked gate

    private var lockedGate: some View {
        ContentUnavailableView {
            Label("Vault Locked", systemImage: "lock.shield.fill")
        } description: {
            Text("Use Face ID or Touch ID to unlock the Vault. Holds private media and secure notes.")
            if let authError {
                Text(authError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } actions: {
            Button {
                authenticate()
            } label: {
                if authenticating {
                    HStack { ProgressView(); Text("Authenticating…") }
                } else {
                    Label("Unlock", systemImage: "faceid")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authenticating)
        }
    }

    private func authenticate() {
        let context = LAContext()
        context.localizedReason = "Unlock the Vault"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = error?.localizedDescription ?? "Biometric authentication unavailable on this device."
            return
        }
        authenticating = true
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the Vault") { success, evalError in
            DispatchQueue.main.async {
                authenticating = false
                if success {
                    unlocked = true
                    authError = nil
                } else {
                    authError = evalError?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }

    // MARK: - Vault list

    private var vaultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                ForEach(vaultItems) { item in
                    NavigationLink(value: item.id) {
                        OperatorCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            store.toggleArchive(id: item.id)
                        } label: {
                            Label(item.archived ? "Unarchive" : "Archive",
                                  systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            store.delete(id: item.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var emptyVault: some View {
        ContentUnavailableView {
            Label("Vault is empty", systemImage: "tray.full")
        } description: {
            Text("Media and secure notes you create here stay behind biometric authentication. Tap the plus button to add your first private record.")
        } actions: {
            Button {
                showingNewRecord = true
            } label: {
                Label("New Record", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
