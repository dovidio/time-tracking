import Foundation

/// Turns days into worked time, balances, and the one number that changes
/// behaviour: the time you can leave.
public struct BalanceEngine: Sendable {

    public var config: Config
    public var calendar: Calendar

    public init(config: Config, calendar: Calendar = BalanceEngine.defaultCalendar) {
        self.config = config
        self.calendar = calendar
    }

    public static var defaultCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        calendar.timeZone = .current
        return calendar
    }

    // MARK: - Calendar rules

    public func dayKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public func isHoliday(_ date: Date) -> Bool {
        config.holidays[dayKey(for: date)] != nil
    }

    public func isWorkday(_ date: Date) -> Bool {
        guard !config.workdays.isEmpty else { return false }
        return config.workdays.contains(calendar.component(.weekday, from: date)) && !isHoliday(date)
    }

    /// The contractual target for one day. Zero on weekends and holidays.
    public func dailyTarget(for date: Date) -> TimeInterval {
        guard isWorkday(date) else { return 0 }
        return config.weeklyHours * 3600 / Double(config.workdays.count)
    }

    public func isTracking(_ date: Date) -> Bool {
        guard let start = config.trackingStart else { return true }
        return calendar.startOfDay(for: date) >= calendar.startOfDay(for: start)
    }

    // MARK: - Day summaries

    public func summary(for day: Day, now: Date) -> DaySummary {
        let isToday = calendar.isDate(day.date, inSameDayAs: now)
        let stamps = day.stamps
            .map { stamp in
                Stamp(
                    id: stamp.id,
                    timestamp: rounded(stamp.timestamp),
                    isManual: stamp.isManual
                )
            }
            .sorted { $0.timestamp < $1.timestamp }

        let segments = DayBuilder.segments(for: stamps)
        let target = dailyTarget(for: day.date)
        let present = workedDuration(segments, isToday: isToday, now: now)
        let deduction = lunchDeduction(present: present, segments: segments, target: target)
        let worked = max(0, present - deduction)
        let leaveAt = leaveTime(segments, target: target, worked: worked, isToday: isToday, now: now)
        let anomalies = anomalies(
            for: day,
            segments: segments,
            target: target,
            isToday: isToday,
            now: now
        )

        return DaySummary(
            day: Day(date: day.date, stamps: stamps, segments: segments),
            worked: worked,
            present: present,
            lunchDeduction: deduction,
            target: target,
            leaveAt: leaveAt,
            anomalies: anomalies
        )
    }

    public func summary(for date: Date, existing: [Day], now: Date) -> DaySummary {
        let day = existing.first { calendar.isDate($0.date, inSameDayAs: date) }
            ?? Day(date: calendar.startOfDay(for: date), stamps: [], segments: [])
        return summary(for: day, now: now)
    }

    public func summaries(for days: [Day], now: Date) -> [DaySummary] {
        days
            .filter { $0.date <= now }
            .map { summary(for: $0, now: now) }
            .sorted { $0.day.date > $1.day.date }
    }

    // MARK: - Periods

    public func weekInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 7 * 86_400)
    }

    public func monthInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 30 * 86_400)
    }

    /// Sums the balance across a period. Days before `trackingStart` are
    /// skipped, and future days are never counted as a deficit.
    public func balance(for days: [Day], in interval: DateInterval, now: Date) -> PeriodBalance {
        let startOfToday = calendar.startOfDay(for: now)
        let first = calendar.startOfDay(for: interval.start)
        let lastOfInterval = calendar.date(byAdding: .day, value: -1, to: interval.end)
            ?? interval.end
        let last = min(calendar.startOfDay(for: lastOfInterval), startOfToday)

        var summaries: [DaySummary] = []
        var cursor = first

        while cursor <= last {
            if isTracking(cursor) {
                summaries.append(summary(for: cursor, existing: days, now: now))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return PeriodBalance(start: first, end: last, days: summaries.sorted { $0.day.date < $1.day.date })
    }

    public func weekBalance(for days: [Day], now: Date) -> PeriodBalance {
        balance(for: days, in: weekInterval(containing: now), now: now)
    }

    public func monthBalance(for days: [Day], now: Date) -> PeriodBalance {
        balance(for: days, in: monthInterval(containing: now), now: now)
    }

    // MARK: - Internals

    /// A standard lunch applies only to a working day with no recorded break.
    /// If you stamped out and back in, the real break is already excluded from
    /// presence and this returns zero.
    private func lunchDeduction(
        present: TimeInterval,
        segments: [Segment],
        target: TimeInterval
    ) -> TimeInterval {
        guard config.standardLunchMinutes > 0, target > 0 else { return 0 }
        guard !segments.contains(where: { $0.kind == .rest }) else { return 0 }

        let lunch = TimeInterval(config.standardLunchMinutes * 60)
        // Never wipe out a very short presence: only apply it when you were
        // there at least as long as the standard lunch.
        return present >= lunch ? lunch : 0
    }

    private func workedDuration(_ segments: [Segment], isToday: Bool, now: Date) -> TimeInterval {
        segments
            .filter { $0.kind == .work }
            .reduce(0) { total, segment in
                let end: Date
                if let closed = segment.end {
                    end = closed
                } else if isToday {
                    end = max(now, segment.start)
                } else {
                    // A missing end on a past day: we refuse to invent hours.
                    end = segment.start
                }
                return total + max(0, end.timeIntervalSince(segment.start))
            }
    }

    private func leaveTime(
        _ segments: [Segment],
        target: TimeInterval,
        worked: TimeInterval,
        isToday: Bool,
        now: Date
    ) -> Date? {
        guard isToday,
              let last = segments.last,
              last.kind == .work,
              last.isOpen else {
            return nil
        }
        return now.addingTimeInterval(max(0, target - worked))
    }

    private func anomalies(
        for day: Day,
        segments: [Segment],
        target: TimeInterval,
        isToday: Bool,
        now: Date
    ) -> [Anomaly] {
        var found: Set<Anomaly> = []

        if day.stamps.isEmpty {
            let hour = calendar.component(.hour, from: now)
            if target > 0, isTracking(day.date), !isToday || hour >= 20 {
                found.insert(.missingDay)
            }
            return found.sorted { $0.rawValue < $1.rawValue }
        }

        let open = segments.last?.isOpen == true
        if open {
            // An open segment during the working day is normal. It becomes an
            // anomaly once the day is over, or late in the evening.
            let hour = calendar.component(.hour, from: now)
            if !isToday || hour >= 20 {
                found.insert(.openDay)
            }
        }

        for segment in segments {
            guard let end = segment.end else { continue }
            let duration = end.timeIntervalSince(segment.start)
            if segment.kind == .work, duration > 12 * 3600 {
                found.insert(.longWorkSegment)
            }
            if segment.kind == .rest, duration > 4 * 3600 {
                found.insert(.longBreak)
            }
        }

        if target > 0,
           let first = day.stamps.first,
           calendar.component(.hour, from: first.timestamp) >= 12 {
            found.insert(.lateFirstStamp)
        }

        return found.sorted { $0.rawValue < $1.rawValue }
    }

    private func rounded(_ date: Date) -> Date {
        guard config.roundingMinutes > 0 else { return date }
        let step = TimeInterval(config.roundingMinutes * 60)
        let startOfDay = calendar.startOfDay(for: date)
        let offset = date.timeIntervalSince(startOfDay)
        let roundedOffset = (offset / step).rounded() * step
        return startOfDay.addingTimeInterval(roundedOffset)
    }
}
