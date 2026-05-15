import SwiftUI
import AVFoundation
import EventKit
import Contacts

/// Inline list of iOS permissions OPerationsHOS uses, with a Grant button per
/// permission that pre-fires the system prompt before the user encounters the
/// just-in-time flow. Status updates after each request. Pattern matches Apple's
/// own Privacy & Security section (denied → user must visit Settings.app).
struct PermissionsSettingsView: View {

    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var remindersStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var calendarStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @State private var contactsStatus: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

    private let eventStore = EKEventStore()
    private let contactStore = CNContactStore()

    var body: some View {
        Section {
            permissionRow(
                title: "Camera",
                symbol: "camera",
                statusText: cameraStatusText,
                granted: cameraStatus == .authorized,
                denied: cameraStatus == .denied || cameraStatus == .restricted
            ) {
                requestCameraAccess()
            }

            permissionRow(
                title: "Reminders",
                symbol: "checklist",
                statusText: ekStatusText(remindersStatus),
                granted: isGrantedReminders(remindersStatus),
                denied: remindersStatus == .denied || remindersStatus == .restricted
            ) {
                requestRemindersAccess()
            }

            permissionRow(
                title: "Calendar",
                symbol: "calendar",
                statusText: ekStatusText(calendarStatus),
                granted: isGrantedCalendar(calendarStatus),
                denied: calendarStatus == .denied || calendarStatus == .restricted
            ) {
                requestCalendarAccess()
            }

            permissionRow(
                title: "Contacts",
                symbol: "person.crop.circle",
                statusText: contactsStatusText,
                granted: contactsStatus == .authorized,
                denied: contactsStatus == .denied || contactsStatus == .restricted
            ) {
                requestContactsAccess()
            }
        } header: {
            Text("Privacy & Security Permissions")
        } footer: {
            Text("Grant in advance so the camera scanner, EventKit sync, and Contacts integration work without interruption later. Denied permissions can be changed from Settings \u{203A} OPerationsHOS in the iOS Settings app.")
        }
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        symbol: String,
        statusText: String,
        granted: Bool,
        denied: Bool,
        request: @escaping () -> Void
    ) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(statusText)
                .font(.caption)
                .foregroundStyle(granted ? Color.green : (denied ? Color.red : Color.secondary))
            if !granted && !denied {
                Button("Grant") { request() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Camera

    private var cameraStatusText: String {
        switch cameraStatus {
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    // MARK: - EventKit (Reminders / Calendar)

    private func ekStatusText(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not requested"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorized: return "Granted"
        case .fullAccess: return "Granted"
        case .writeOnly: return "Write only"
        @unknown default: return "Unknown"
        }
    }

    private func isGrantedReminders(_ status: EKAuthorizationStatus) -> Bool {
        status == .fullAccess || status == .authorized
    }

    private func isGrantedCalendar(_ status: EKAuthorizationStatus) -> Bool {
        status == .fullAccess || status == .authorized
    }

    private func requestRemindersAccess() {
        if #available(iOS 17.0, macOS 14.0, *) {
            Task { @MainActor in
                _ = try? await eventStore.requestFullAccessToReminders()
                remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { _, _ in
                DispatchQueue.main.async {
                    remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
                }
            }
        }
    }

    private func requestCalendarAccess() {
        if #available(iOS 17.0, macOS 14.0, *) {
            Task { @MainActor in
                _ = try? await eventStore.requestFullAccessToEvents()
                calendarStatus = EKEventStore.authorizationStatus(for: .event)
            }
        } else {
            eventStore.requestAccess(to: .event) { _, _ in
                DispatchQueue.main.async {
                    calendarStatus = EKEventStore.authorizationStatus(for: .event)
                }
            }
        }
    }

    // MARK: - Contacts

    private var contactsStatusText: String {
        switch contactsStatus {
        case .notDetermined: return "Not requested"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorized: return "Granted"
        case .limited: return "Limited"
        @unknown default: return "Unknown"
        }
    }

    private func requestContactsAccess() {
        contactStore.requestAccess(for: .contacts) { _, _ in
            DispatchQueue.main.async {
                contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
        }
    }
}
