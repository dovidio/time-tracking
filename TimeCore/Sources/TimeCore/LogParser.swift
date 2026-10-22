import Foundation

/// Reads and writes the append-only log.
///
/// Line format:
/// ```
/// 2025-06-12T08:52:31+02:00|stamp
/// 2025-06-12T12:31:07+02:00|stamp
/// 2025-06-12T17:49:10+02:00|undo
/// 2025-06-12T20:15:00+02:00|day|2025-06-12|08:52|12:31|13:14|17:48
/// ```
public enum LogParser {

    public static func parse(_ text: String) -> [LogEntry] {
        text
            .split(whereSeparator: \.isNewline)
            .compactMap { parseLine(String($0)) }
    }

    public static func parseLine(_ line: String) -> LogEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let fields = trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map(String.init)

        guard fields.count >= 2,
              let date = date(from: fields[0]),
              let kind = LogEntryKind(rawValue: fields[1]) else {
            return nil
        }

        return LogEntry(
            timestamp: date,
            kind: kind,
            raw: trimmed,
            fields: Array(fields.dropFirst(2))
        )
    }

    public static func line(
        for date: Date,
        kind: LogEntryKind,
        timeZone: TimeZone = .current
    ) -> String {
        [timestampString(for: date, timeZone: timeZone), kind.rawValue].joined(separator: "|")
    }

    /// A manual correction for one day.
    ///
    /// ```
    /// 2025-06-12T20:15:00+02:00|day|2025-06-12|08:00|12:00|13:00|17:00|note=forgot evening tap
    /// ```
    /// An empty `times` array writes a line that clears the previous override
    /// for that day.
    public static func overrideLine(
        for day: Date,
        times: [Date],
        note: String?,
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = timeZone
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = "HH:mm"

        var fields = [
            timestampString(for: now, timeZone: timeZone),
            LogEntryKind.dayOverride.rawValue,
            dayFormatter.string(from: day)
        ]
        fields.append(contentsOf: times.sorted().map { timeFormatter.string(from: $0) })
        if let note, !note.trimmingCharacters(in: .whitespaces).isEmpty {
            fields.append("note=" + note.replacingOccurrences(of: "|", with: "/"))
        }
        return fields.joined(separator: "|")
    }

    /// Removes a manual correction for one day.
    public static func clearOverrideLine(
        for day: Date,
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return [
            timestampString(for: now, timeZone: timeZone),
            LogEntryKind.dayClear.rawValue,
            formatter.string(from: day)
        ].joined(separator: "|")
    }

    public static func timestampString(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return formatter.string(from: date)
    }

    public static func date(from string: String) -> Date? {
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: string) { return date }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return fallback.date(from: string)
    }
}
