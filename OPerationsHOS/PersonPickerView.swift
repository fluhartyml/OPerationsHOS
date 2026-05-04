import SwiftUI
import Contacts

#if os(iOS)
import ContactsUI

struct PersonPickerView: UIViewControllerRepresentable {
    let onPick: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (CNContact) -> Void
        init(onPick: @escaping (CNContact) -> Void) { self.onPick = onPick }
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onPick(contact)
        }
    }
}
#endif

@MainActor
@Observable
final class ContactsAccess {
    enum AuthState { case unknown, authorized, denied, notDetermined }
    var authState: AuthState = .unknown

    private let store = CNContactStore()

    func refreshAuth() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: authState = .authorized
        case .denied, .restricted: authState = .denied
        case .notDetermined: authState = .notDetermined
        @unknown default: authState = .unknown
        }
    }

    func requestAccess() async {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            authState = granted ? .authorized : .denied
        } catch {
            authState = .denied
        }
    }
}

func displayName(for contact: CNContact) -> String {
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    let formatted = formatter.string(from: contact) ?? ""
    if !formatted.isEmpty { return formatted }
    let combined = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    return combined.isEmpty ? "Unnamed" : combined
}
