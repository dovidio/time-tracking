import Foundation

/// The kinds of line the append-only log can contain.
///
/// The log is a transcript of gestures, not a table of results. `undo` is itself
/// a line: a mistake is corrected by appending, never by rewriting history.
public enum LogEntryKind: String, Codable, Sendable {
    case stamp
    case undo
    /// A manual correction for one day. Supersedes the recorded stamps for
    /// that date. With no times it means "this day has no stamps".
    case dayOverride = "day"
    /// Removes any manual correction for a date, letting recorded taps show
    /// through again.
    case dayClear = "dayclear"
}

public struct LogEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let kind: LogEntryKind
    public let raw: String
    /// Remaining pipe-separated fields, for entry kinds that carry data
    /// (`day` overrides). Kept raw so time-zone handling stays in the engine.
    public let fields: [String]

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        kind: LogEntryKind,
        raw: String = "",
        fields: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.raw = raw
        self.fields = fields
    }
}

/// A surviving stamp after `undo` lines have been applied.
public struct Stamp: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    /// True when this stamp comes from a manual day correction rather than
    /// a recorded tap.
    public let isManual: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        isManual: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.isManual = isManual
    }
}

/// A manual correction for a single day.
public struct DayOverride: Hashable, Sendable {
    public let date: Date
    public let times: [Date]
    public let note: String?

    public init(date: Date, times: [Date], note: String? = nil) {
        self.date = date
        self.times = times
        self.note = note
    }
}

/// A stretch of the day between two consecutive stamps.
///
/// Segments alternate work / rest starting with work, mirroring the terminal's
/// toggle: the first stamp of the day always opens a work segment.
public struct Segment: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case work
        case rest
    }

    public let id: UUID
    public let kind: Kind
    public let start: Date
    public let end: Date?

    public var isOpen: Bool { end == nil }

    public var duration: TimeInterval? {
        end.map { $0.timeIntervalSince(start) }
    }

    public init(id: UUID = UUID(), kind: Kind, start: Date, end: Date?) {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
    }
}

public struct Day: Identifiable, Hashable, Sendable {
    public let date: Date
    public let stamps: [Stamp]
    public let segments: [Segment]

    public var id: Date { date }

    public init(date: Date, stamps: [Stamp], segments: [Segment]) {
        self.date = date
        self.stamps = stamps
        self.segments = segments
    }
}

/// Things worth telling the user about, because they usually mean the log and
/// reality have drifted apart.
public enum Anomaly: String, Hashable, Sendable, CaseIterable {
    /// The day ended with an unclosed segment: a missing stamp.
    case openDay
    /// A single work segment longer than 12 hours.
    case longWorkSegment
    /// A single break longer than 4 hours.
    case longBreak
    /// First stamp of the day after noon, which usually means a missed arrival.
    case lateFirstStamp
    /// A working day with no stamps at all, after tracking started.
    case missingDay

    public var message: String {
        switch self {
        case .openDay: return "Day never closed — a stamp is missing."
        case .longWorkSegment: return "A work stretch over 12 hours."
        case .longBreak: return "A break over 4 hours."
        case .lateFirstStamp: return "First stamp after noon — arrival may be missing."
        case .missingDay: return "No stamps on a working day."
        }
    }
}

public struct DaySummary: Identifiable, Hashable, Sendable {
    public let day: Day
    /// Credited work: presence minus any standard lunch deduction.
    public let worked: TimeInterval
    /// Raw presence, before the standard lunch deduction.
    public let present: TimeInterval
    /// The standard lunch applied to this day, or zero.
    public let lunchDeduction: TimeInterval
    public let target: TimeInterval
    public let leaveAt: Date?
    public let anomalies: [Anomaly]

    public var id: Date { day.date }
    public var balance: TimeInterval { worked - target }

    public var isWorking: Bool {
        guard let last = day.segments.last else { return false }
        return last.kind == .work && last.isOpen
    }

    /// Stamped out. Whether that means lunch or the end of the day is a
    /// question of context, not of log structure, so the UI decides.
    public var isOut: Bool {
        !isWorking && !day.stamps.isEmpty
    }

    public var lastStamp: Stamp? { day.stamps.last }

    public var isClosed: Bool {
        guard let last = day.segments.last else { return false }
        return last.end != nil
    }

    public var hasStamps: Bool { !day.stamps.isEmpty }

    public init(
        day: Day,
        worked: TimeInterval,
        present: TimeInterval = 0,
        lunchDeduction: TimeInterval = 0,
        target: TimeInterval,
        leaveAt: Date?,
        anomalies: [Anomaly]
    ) {
        self.day = day
        self.worked = worked
        self.present = present
        self.lunchDeduction = lunchDeduction
        self.target = target
        self.leaveAt = leaveAt
        self.anomalies = anomalies
    }
}

public struct PeriodBalance: Sendable {
    public let start: Date
    public let end: Date
    public let days: [DaySummary]

    public var worked: TimeInterval { days.reduce(0) { $0 + $1.worked } }
    public var target: TimeInterval { days.reduce(0) { $0 + $1.target } }
    public var balance: TimeInterval { worked - target }

    public init(start: Date, end: Date, days: [DaySummary]) {
        self.start = start
        self.end = end
        self.days = days
    }
}

public struct Config: Codable, Hashable, Sendable {
    /// Contractual hours per week. The daily target is this divided by the
    /// number of working days.
    public var weeklyHours: Double
    /// `Calendar` weekday numbers: 1 = Sunday … 7 = Saturday. Default Mon–Fri.
    public var workdays: Set<Int>
    /// 0 keeps raw times. 5, 10, 15 and 30 mirror terminals that round punches.
    public var roundingMinutes: Int
    /// `yyyy-MM-dd` → label. A holiday has a zero target.
    public var holidays: [String: String]
    /// Days before this are ignored when computing a period balance, so a fresh
    /// install doesn't look like months of missing hours.
    public var trackingStart: Date?
    /// Deducted on a working day where no break was recorded. Zero means off.
    /// A recorded break always wins over this.
    public var standardLunchMinutes: Int

    public init(
        weeklyHours: Double = 42,
        workdays: Set<Int> = [2, 3, 4, 5, 6],
        roundingMinutes: Int = 0,
        holidays: [String: String] = [:],
        trackingStart: Date? = nil,
        standardLunchMinutes: Int = 0
    ) {
        self.weeklyHours = weeklyHours
        self.workdays = workdays
        self.roundingMinutes = roundingMinutes
        self.holidays = holidays
        self.trackingStart = trackingStart
        self.standardLunchMinutes = standardLunchMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case weeklyHours
        case workdays
        case roundingMinutes
        case holidays
        case trackingStart
        case standardLunchMinutes
    }

    /// Tolerates configuration written before a field existed.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        weeklyHours = try container.decodeIfPresent(Double.self, forKey: .weeklyHours) ?? 42
        workdays = try container.decodeIfPresent(Set<Int>.self, forKey: .workdays) ?? [2, 3, 4, 5, 6]
        roundingMinutes = try container.decodeIfPresent(Int.self, forKey: .roundingMinutes) ?? 0
        holidays = try container.decodeIfPresent([String: String].self, forKey: .holidays) ?? [:]
        trackingStart = try container.decodeIfPresent(Date.self, forKey: .trackingStart)
        standardLunchMinutes = try container.decodeIfPresent(Int.self, forKey: .standardLunchMinutes) ?? 0
    }
}
