import AppIntents
import Foundation

/// Exposed to Siri, Shortcuts, and a Lock Screen Shortcuts widget, so a stamp
/// can happen without opening the app.

struct StampIntent: AppIntent {
    static var title: LocalizedStringResource = "Stamp"
    static var description = IntentDescription("Record a stamp at the current time.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = LogStore()
        let instant = Date()
        do {
            try StampWriter.stamp(at: instant, store: store, calendar: BalanceEngine.defaultCalendar)
            NotificationCenter.default.post(name: .timeTrackerLogChanged, object: nil)
            return .result(dialog: "Stamped at \(Format.time(instant))")
        } catch {
            return .result(dialog: "Stamp failed: \(error.localizedDescription)")
        }
    }
}

struct UndoStampIntent: AppIntent {
    static var title: LocalizedStringResource = "Undo last stamp"
    static var description = IntentDescription("Remove the most recent stamp from the log.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = LogStore()
        do {
            try StampWriter.undo(at: Date(), store: store, calendar: BalanceEngine.defaultCalendar)
            NotificationCenter.default.post(name: .timeTrackerLogChanged, object: nil)
            return .result(dialog: "Last stamp removed.")
        } catch {
            return .result(dialog: "Undo failed: \(error.localizedDescription)")
        }
    }
}

struct TimeTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StampIntent(),
            phrases: [
                "Stamp with \(.applicationName)",
                "Timbra con \(.applicationName)"
            ],
            shortTitle: "Stamp",
            systemImageName: "clock.badge.checkmark"
        )
        AppShortcut(
            intent: UndoStampIntent(),
            phrases: [
                "Undo stamp with \(.applicationName)",
                "Annulla timbratura con \(.applicationName)"
            ],
            shortTitle: "Undo stamp",
            systemImageName: "arrow.uturn.backward"
        )
    }
}
