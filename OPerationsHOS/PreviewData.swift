import Foundation

enum PreviewData {
    static let sampleItems: [OperatorItem] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let inDays: (Int) -> Date = { cal.date(byAdding: .day, value: $0, to: today)! }

        return [
            OperatorItem(
                title: "HVAC Coil Warranty",
                subtitle: "Active until 03/31/2027",
                body: "Tech found leak 03/19. Replacement pending. Coil warranty confirmed through 03/31/2027. Invoice still needed from contractor.",
                type: .warranty,
                status: .active,
                priority: .high,
                createdDate: inDays(-14),
                updatedDate: inDays(-2),
                pinned: true,
                tags: ["hvac", "warranty", "home"],
                relatedSystem: "HVAC"
            ),
            OperatorItem(
                title: "Whirlpool Refrigerator Replacement",
                subtitle: "Delivery scheduled 10 AM – 2 PM",
                body: "Replacement model ordered. Delivery window 10–2. Old unit pickup confirmed. Receipt pending.",
                type: .appliance,
                status: .scheduled,
                priority: .high,
                createdDate: inDays(-10),
                updatedDate: inDays(-1),
                dueDate: inDays(2),
                pinned: true,
                tags: ["appliance", "kitchen"],
                relatedSystem: "Kitchen"
            ),
            OperatorItem(
                title: "Solar Array Invoice",
                subtitle: "Invoice missing",
                body: "Installer hasn't sent final invoice. Need this for property docs and warranty record. Contact installer this week.",
                type: .document,
                status: .waiting,
                priority: .normal,
                createdDate: inDays(-21),
                updatedDate: inDays(-7),
                dueDate: inDays(3),
                tags: ["solar", "invoice", "property"],
                relatedSystem: "Solar"
            ),
            OperatorItem(
                title: "Property Sale Prep",
                subtitle: "Wash, document, stage",
                body: "Wash exterior. Gather all home docs. Fix guest sink drip. Stage interior. Collect solar paperwork. Inspection scheduled next month.",
                type: .project,
                status: .active,
                priority: .high,
                createdDate: inDays(-30),
                updatedDate: today,
                pinned: true,
                tags: ["sale", "property", "prep"],
                relatedSystem: "Property"
            ),
            OperatorItem(
                title: "Starlink Hardware",
                subtitle: "Receipt and warranty packet",
                body: "Hardware delivered 2026-04-12. Activation complete. Receipt filed. Warranty registered.",
                type: .document,
                status: .complete,
                priority: .low,
                createdDate: inDays(-22),
                updatedDate: inDays(-22),
                tags: ["starlink", "internet", "warranty"],
                relatedSystem: "Internet"
            ),
            OperatorItem(
                title: "Guest Sink Hot Side Drip",
                subtitle: "Repair before listing",
                body: "Hot side drips. Cartridge replacement likely fix. Low priority but must clear before sale prep is complete.",
                type: .maintenance,
                status: .open,
                priority: .low,
                createdDate: inDays(-5),
                updatedDate: inDays(-5),
                tags: ["plumbing", "guest-bath", "sale-prep"],
                relatedSystem: "Plumbing"
            ),
            OperatorItem(
                title: "Weekly Workflow Planning",
                subtitle: "Sunday review session",
                body: "Sundays — review the week, set priorities, clear inboxes, schedule deep-work blocks.",
                type: .timer,
                status: .active,
                priority: .normal,
                createdDate: inDays(-60),
                updatedDate: today,
                dueDate: inDays(0),
                tags: ["workflow", "planning"],
                relatedSystem: "Workflow"
            ),
            OperatorItem(
                title: "Bob — HVAC Contractor",
                subtitle: "Last call 03/19 about coil leak",
                body: "Came out for the coil leak. Confirmed warranty coverage through 03/31/2027. Owe him a follow-up on replacement scheduling. Reliable, calls back same day.",
                type: .person,
                status: .active,
                priority: .normal,
                createdDate: inDays(-90),
                updatedDate: inDays(-2),
                tags: ["hvac", "contractor", "vendor"],
                relatedSystem: "HVAC"
            )
        ]
    }()
}
