import Combine
import Foundation
import UIKit

extension Notification.Name {
    /// Posted by the App Intents after they append to the log, so an open app
    /// picks the stamp up immediately.
    static let timeTrackerLogChanged = Notification.Name("TimeTrackerLogChanged")
}

@MainActor
final class AppModel: ObservableObject {
    @Published var config: Config
    @Published var entries: [LogEntry] = []
    @Published var now: Date = .now
    @Published var lastWriteError: String?

    let store: LogStore
    private var logObserver: AnyCancellable?

    private static let configKey = "timeTracker.config.v1"

    init(store: LogStore = LogStore()) {
        self.store = store
        self.config = Self.loadConfig()
        self.entries = store.load()
        syncTrackingStart()

        logObserver = NotificationCenter.default
            .publisher(for: .timeTrackerLogChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reload()
            }
    }

    // MARK: - Derived state

    var calendar: Calendar { BalanceEngine.defaultCalendar }

    var engine: BalanceEngine {
        BalanceEngine(config: config, calendar: calendar)
    }

    var stamps: [Stamp] {
        EventLog.resolve(entries)
    }

    var overrides: [Date: DayOverride] {
        EventLog.overrides(entries, calendar: calendar)
    }

    var days: [Day] {
        DayBuilder.days(from: stamps, overrides: overrides, calendar: calendar)
    }

    var today: DaySummary {
        engine.summary(for: now, existing: days, now: now)
    }

    var week: PeriodBalance {
        engine.weekBalance(for: days, now: now)
    }

    var month: PeriodBalance {
        engine.monthBalance(for: days, now: now)
    }

    /// Days with stamps, newest first.
    var history: [DaySummary] {
        engine.summaries(for: days, now: now)
    }

    var logURL: URL { store.url }

    var todayOverride: DayOverride? {
        overrides[calendar.startOfDay(for: now)]
    }

    var nextActionTitle: String {
        switch today.day.stamps.count {
        case 0:
            return "Stamp in"
        case 1:
            return calendar.component(.hour, from: now) < 14 ? "Break" : "Stamp out"
        default:
            if today.isWorking { return "Stamp out" }
            return today.day.stamps.count >= 4 ? "Stamp in" : "Back in"
        }
    }

    var buttonIcon: String {
        today.isWorking ? "pause.fill" : "arrow.right.to.line"
    }

    var stateTitle: String {
        guard let last = today.lastStamp else { return "Not stamped in" }
        if today.isWorking {
            return "Working since \(Format.time(last.timestamp))"
        }
        let hour = calendar.component(.hour, from: last.timestamp)
        return hour < 16
            ? "On break since \(Format.time(last.timestamp))"
            : "Day closed at \(Format.time(last.timestamp))"
    }

    // MARK: - Actions

    func stamp() {
        let instant = Date()
        do {
            try StampWriter.stamp(at: instant, store: store, calendar: calendar)
            lastWriteError = nil
        } catch {
            lastWriteError = error.localizedDescription
            return
        }

        syncTrackingStart()
        reload()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func reload() {
        now = Date()
        entries = store.load()
        syncTrackingStart()
    }

    // MARK: - Manual corrections

    /// Appends a `day` line that supersedes the recorded stamps for `date`.
    /// An empty `times` array means "this day has no stamps".
    func setOverride(for date: Date, times: [Date], note: String?) {
        do {
            try store.append(
                LogParser.overrideLine(
                    for: date,
                    times: times,
                    note: note,
                    timeZone: calendar.timeZone
                )
            )
            lastWriteError = nil
            reload()
        } catch {
            lastWriteError = error.localizedDescription
        }
    }

    /// Removes any manual correction for `date`, so recorded taps show again.
    func clearOverride(for date: Date) {
        do {
            try store.append(
                LogParser.clearOverrideLine(
                    for: date,
                    timeZone: calendar.timeZone
                )
            )
            lastWriteError = nil
            reload()
        } catch {
            lastWriteError = error.localizedDescription
        }
    }

    // MARK: - Configuration

    func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: Self.configKey)
    }

    func addHoliday(_ date: Date, name: String) {
        let key = engine.dayKey(for: date)
        config.holidays[key] = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Holiday" : name
        saveConfig()
    }

    func removeHoliday(_ key: String) {
        config.holidays.removeValue(forKey: key)
        saveConfig()
    }

    func resetTrackingStart() {
        config.trackingStart = calendar.startOfDay(for: .now)
        saveConfig()
    }

    // MARK: - Helpers

    /// Keeps the balance honest on a fresh install: the period starts at the
    /// first recorded stamp, not at the beginning of time.
    private func syncTrackingStart() {
        let earliest = entries.compactMap { entry -> Date? in
            entry.kind == .stamp ? entry.timestamp : nil
        }.min()

        if let earliest {
            let day = calendar.startOfDay(for: earliest)
            if let current = config.trackingStart {
                if day < calendar.startOfDay(for: current) {
                    config.trackingStart = day
                    saveConfig()
                }
            } else {
                config.trackingStart = day
                saveConfig()
            }
        } else if config.trackingStart == nil {
            config.trackingStart = calendar.startOfDay(for: .now)
            saveConfig()
        }
    }

    private static func loadConfig() -> Config {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return Config()
        }
        return config
    }
}
