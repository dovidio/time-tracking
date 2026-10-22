import Foundation

/// Decides which log lines a gesture should append.
///
/// A recorded stamp on a day that has a manual correction would otherwise be
/// silently ignored, because a correction supersedes the day's recorded
/// stamps. Instead, the stamp extends the corrected timeline by writing a new
/// `day` line that includes the new time.
public enum WritePlanner {

    public static func stampLines(
        at instant: Date,
        entries: [LogEntry],
        calendar: Calendar = .current
    ) -> [String] {
        let overrides = EventLog.overrides(entries, calendar: calendar)
        let day = calendar.startOfDay(for: instant)

        guard let override = overrides[day] else {
            return [LogParser.line(for: instant, kind: .stamp, timeZone: calendar.timeZone)]
        }

        var times = override.times
        times.append(instant)
        times.sort()
        return [
            LogParser.overrideLine(
                for: day,
                times: times,
                note: override.note,
                timeZone: calendar.timeZone,
                now: instant
            )
        ]
    }

    public static func undoLines(
        at instant: Date,
        entries: [LogEntry],
        calendar: Calendar = .current
    ) -> [String] {
        let overrides = EventLog.overrides(entries, calendar: calendar)
        let day = calendar.startOfDay(for: instant)

        guard let override = overrides[day] else {
            return [LogParser.line(for: instant, kind: .undo, timeZone: calendar.timeZone)]
        }

        guard !override.times.isEmpty else { return [] }

        var times = override.times
        times.removeLast()

        if times.isEmpty {
            return [LogParser.clearOverrideLine(for: day, timeZone: calendar.timeZone, now: instant)]
        }

        return [
            LogParser.overrideLine(
                for: day,
                times: times,
                note: override.note,
                timeZone: calendar.timeZone,
                now: instant
            )
        ]
    }
}
