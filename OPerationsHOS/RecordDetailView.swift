import SwiftUI
import SwiftData
import PhotosUI
import Contacts
import QuickLook
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct RecordDetailView: View {
    let id: UUID
    let store: OperatorStore

    @State private var showingEdit = false
    @State private var showingDocumentPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var quickLookURL: URL?
    @Environment(\.dismiss) private var dismiss

    private var item: OperatorItem? {
        store.item(id: id)
    }

    private var contact: CNContact? {
        guard let item, item.type == .person else { return nil }
        guard let identifier = item.source, !identifier.isEmpty else { return nil }
        return lookupContact(identifier: identifier)
    }

    var body: some View {
        Group {
            if let item {
                content(for: item)
            } else {
                ContentUnavailableView("Record Removed", systemImage: "trash")
            }
        }
        .navigationTitle(item?.title ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let item {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button {
                            store.togglePin(id: item.id)
                        } label: {
                            Label(item.pinned ? "Unpin" : "Pin",
                                  systemImage: item.pinned ? "pin.slash" : "pin")
                        }
                        Button {
                            store.toggleArchive(id: item.id)
                        } label: {
                            Label(item.archived ? "Unarchive" : "Archive",
                                  systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            store.delete(id: item.id)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecordEditSheet(mode: .edit(id), store: store)
        }
    }

    @ViewBuilder
    private func content(for item: OperatorItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                header(for: item)
                if let contact {
                    contactPhoto(for: contact)
                    quickActions(for: contact)
                    contactDetails(for: contact)
                }
                metadata(for: item)
                if !item.body.isEmpty {
                    bodySection(for: item)
                }
                if !item.tags.isEmpty {
                    tagsSection(for: item)
                }
                attachmentsSection(for: item)
                placeholders
            }
            .padding()
        }
        #if os(iOS)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .image, .data],
            allowsMultipleSelection: true
        ) { result in
            handleDocumentImport(result, into: item)
        }
        .quickLookPreview($quickLookURL)
        #endif
        .onChange(of: photoItem) { _, newItem in
            handlePhotoPick(newItem, into: item)
        }
    }

    private func contactPhoto(for contact: CNContact) -> some View {
        HStack {
            Spacer()
            Group {
                if contact.imageDataAvailable, let data = contact.imageData, let img = platformImage(from: data) {
                    img.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            Spacer()
        }
    }

    private func quickActions(for contact: CNContact) -> some View {
        let phone = contact.phoneNumbers.first?.value.stringValue
        let email = contact.emailAddresses.first?.value as String?
        return HStack(spacing: 16) {
            quickActionButton(title: "Call", icon: "phone.fill", enabled: phone != nil) {
                if let p = phone { open("tel://\(p.filter { $0.isNumber || $0 == "+" })") }
            }
            quickActionButton(title: "Message", icon: "message.fill", enabled: phone != nil) {
                if let p = phone { open("sms:\(p.filter { $0.isNumber || $0 == "+" })") }
            }
            quickActionButton(title: "Email", icon: "envelope.fill", enabled: email != nil) {
                if let e = email { open("mailto:\(e)") }
            }
        }
    }

    private func quickActionButton(title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
    }

    private func contactDetails(for contact: CNContact) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact Info").font(.headline)
            ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                HStack {
                    Image(systemName: "phone").foregroundStyle(.tint)
                    Text(phone.value.stringValue)
                    Spacer()
                    if let label = phone.label {
                        Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            ForEach(contact.emailAddresses, id: \.identifier) { email in
                HStack {
                    Image(systemName: "envelope").foregroundStyle(.tint)
                    Text(email.value as String)
                    Spacer()
                    if let label = email.label {
                        Text(CNLabeledValue<NSString>.localizedString(forLabel: label))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            if let bday = contact.birthday, let date = Calendar.current.date(from: bday) {
                HStack {
                    Image(systemName: "birthday.cake").foregroundStyle(.tint)
                    Text(date, style: .date)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.cardPadding)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func header(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: item.type.symbol)
                    .font(.title)
                    .foregroundStyle(.tint)
                Text(item.type.label)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
                if item.pinned {
                    Image(systemName: "pin.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if item.archived {
                    Image(systemName: "archivebox.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(item.title).font(.title2.weight(.semibold))
            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metadata(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            row("Status", item.status.label)
            row("Priority", item.priority.label)
            if let due = item.dueDate {
                row("Due", due.formatted(date: .abbreviated, time: .omitted))
            }
            if let system = item.relatedSystem {
                row("Related System", system)
            }
            row("Created", item.createdDate.formatted(date: .abbreviated, time: .omitted))
            row("Updated", item.updatedDate.formatted(date: .abbreviated, time: .omitted))
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    private func bodySection(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.headline)
            Text(item.body)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func tagsSection(for item: OperatorItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags").font(.headline)
            HStack(spacing: 6) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.thinMaterial, in: Capsule())
                }
                Spacer()
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    @ViewBuilder
    private func attachmentsSection(for item: OperatorItem) -> some View {
        let attachments = (item.attachments ?? []).sorted { $0.createdDate > $1.createdDate }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attachments").font(.headline)
                Spacer()
                Menu {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Photo", systemImage: "photo")
                    }
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("File", systemImage: "doc")
                    }
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
            }
            if attachments.isEmpty {
                Text("No attachments yet. Tap + to add a photo or file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(attachments) { attachment in
                    attachmentRow(attachment)
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func attachmentRow(_ attachment: Attachment) -> some View {
        Button {
            quickLookURL = AttachmentStorage.url(for: attachment.filename)
        } label: {
            HStack {
                Image(systemName: attachment.kind.symbol)
                    .foregroundStyle(.tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.originalName.isEmpty ? attachment.filename : attachment.originalName)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(attachment.kind.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteAttachment(attachment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteAttachment(_ attachment: Attachment) {
        AttachmentStorage.delete(filename: attachment.filename)
        store.deleteAttachment(attachment)
    }

    private func handleDocumentImport(_ result: Result<[URL], Error>, into item: OperatorItem) {
        guard case let .success(urls) = result else { return }
        for url in urls {
            do {
                let info = try AttachmentStorage.copy(from: url)
                let attachment = Attachment(
                    filename: info.filename,
                    originalName: info.originalName,
                    kind: AttachmentStorage.kind(for: url)
                )
                store.attach(attachment, to: item)
            } catch {
                continue
            }
        }
    }

    private func handlePhotoPick(_ pickerItem: PhotosPickerItem?, into item: OperatorItem) {
        guard let pickerItem else { return }
        Task {
            do {
                guard let data = try await pickerItem.loadTransferable(type: Data.self) else { return }
                let info = try AttachmentStorage.write(data: data, suggestedExtension: "jpg")
                let attachment = Attachment(
                    filename: info.filename,
                    originalName: info.originalName,
                    kind: .image
                )
                await MainActor.run {
                    store.attach(attachment, to: item)
                    photoItem = nil
                }
            } catch {
                await MainActor.run { photoItem = nil }
            }
        }
    }

    private var placeholders: some View {
        VStack(alignment: .leading, spacing: 12) {
            placeholder("Activity Log", "Will arrive in Phase 10")
        }
    }

    private func placeholder(_ title: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

#if canImport(UIKit)
private func platformImage(from data: Data) -> Image? {
    UIImage(data: data).map { Image(uiImage: $0) }
}
#elseif canImport(AppKit)
private func platformImage(from data: Data) -> Image? {
    NSImage(data: data).map { Image(nsImage: $0) }
}
#endif
