import Foundation

/// Applies the log's semantics: `stamp` pushes, `undo` pops, `day` supersedes.
public enum EventLog {

    /// The stamps that survive after undo lines are applied, oldest first.
    public static func resolve(_ entries: [LogEntry]) -> [Stamp] {
        var stamps: [Stamp] = []

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            switch entry.kind {
            case .stamp:
                stamps.append(Stamp(timestamp: entry.timestamp))

            case .undo:
                if !stamps.isEmpty {
                    stamps.removeLast()
                }

            case .dayOverride, .dayClear:
                continue
            }
        }

        return stamps
    }

    /// Manual day corrections, keyed by the start of the corrected day.
    /// A later line for the same day replaces the earlier one; a line with no
    /// times clears it, so the recorded stamps show through again.
    public static func overrides(_ entries: [LogEntry], calendar: Calendar) -> [Date: DayOverride] {
        var result: [Date: DayOverride] = [:]

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard entry.kind == .dayOverride || entry.kind == .dayClear,
                  let dayKey = entry.fields.first,
                  let day = day(from: dayKey, calendar: calendar) else { continue }

            let key = calendar.startOfDay(for: day)

            if entry.kind == .dayClear {
                result.removeValue(forKey: key)
                continue
            }

            var times: [Date] = []
            var note: String?

            for field in entry.fields.dropFirst() {
                if field.hasPrefix("note=") {
                    note = String(field.dropFirst(5))
                    continue
                }
                if let time = time(from: field, on: day, calendar: calendar) {
                    times.append(time)
                }
            }

            result[key] = DayOverride(date: key, times: times.sorted(), note: note)
        }

        return result
    }

    // MARK: - Field parsing

    private static func day(from key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    private static func time(from text: String, on day: Date, calendar: Calendar) -> Date? {
        let parts = text.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }
}
