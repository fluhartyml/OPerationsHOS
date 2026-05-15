//
//  ShareViewController.swift
//  OPerationsHOSShare
//
//  System share-sheet handler. When a user shares text / URL / image from
//  another iOS app into OPerationsHOS, this extension captures the payload,
//  writes a pending-share entry to the App Group container, then completes.
//  The main app reads those pending entries on next launch and creates Inbox
//  records. Phase 1 routes everything to Inbox; Phase 2 will add a destination
//  picker (Inbox / specific module / specific person).
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private static let appGroupID = "group.com.ChatGPT.OPerationsHOS"
    private static let pendingFilename = "pending-shares.json"

    override func isContentValid() -> Bool {
        // Allow posting even with empty content text — attachments alone are valid.
        return true
    }

    override func didSelectPost() {
        let title = (self.contentText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        captureAttachments { capturedBodyParts, capturedSource in
            let combinedBody = capturedBodyParts.joined(separator: "\n\n")
            let entry: [String: Any] = [
                "title": title.isEmpty ? (capturedSource ?? "Shared item") : title,
                "body": combinedBody,
                "source": capturedSource ?? "",
                "timestamp": Date().timeIntervalSince1970
            ]
            self.appendPending(entry)
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        let destination = SLComposeSheetConfigurationItem()!
        destination.title = "Destination"
        destination.value = "Inbox"
        // Phase 2 will push a picker here. For now: read-only display of the
        // routed destination so the user sees where the shared item lands.
        destination.tapHandler = { [weak self] in
            // No-op for v1; the row exists to communicate destination = Inbox.
            self?.popConfigurationViewController()
        }
        return [destination]
    }

    /// Pull text / URL / image attachments out of the extension context.
    /// Calls the completion with a list of body strings and an optional source label.
    private func captureAttachments(completion: @escaping ([String], String?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion([], nil)
            return
        }

        var bodyParts: [String] = []
        var source: String?
        let group = DispatchGroup()

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                        if let url = data as? URL {
                            bodyParts.append(url.absoluteString)
                            source = url.host ?? source
                        }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, _ in
                        if let str = data as? String {
                            bodyParts.append(str)
                        }
                        group.leave()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    // Defer image-attachment writing to a future commit (needs
                    // App Group container file writes + main-app Attachment
                    // pipeline). Note the presence so the user record has context.
                    bodyParts.append("[Shared image — image attachment support coming]")
                    source = "image"
                }
            }
        }

        group.notify(queue: .main) {
            completion(bodyParts, source)
        }
    }

    /// Append a pending-share entry to the App Group's pending-shares.json file.
    /// Creates the file if it doesn't exist. Atomic write to avoid partial reads.
    private func appendPending(_ entry: [String: Any]) {
        guard let url = Self.pendingFileURL() else { return }
        var existing: [[String: Any]] = []
        if let data = try? Data(contentsOf: url),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            existing = parsed
        }
        existing.append(entry)
        if let data = try? JSONSerialization.data(withJSONObject: existing, options: [.prettyPrinted]) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    private static func pendingFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(pendingFilename)
    }
}
