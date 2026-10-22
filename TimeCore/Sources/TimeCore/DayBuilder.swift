import Foundation

/// Groups stamps into days and turns each day into alternating segments.
public enum DayBuilder {

    public static func days(
        from stamps: [Stamp],
        overrides: [Date: DayOverride] = [:],
        calendar: Calendar = .current
    ) -> [Day] {
        var grouped = Dictionary(grouping: stamps) { stamp in
            calendar.startOfDay(for: stamp.timestamp)
        }

        // A manual correction supersedes the recorded taps for that day.
        for (date, override) in overrides {
            let manual = override.times.map {
                Stamp(timestamp: $0, isManual: true)
            }
            grouped[calendar.startOfDay(for: date)] = manual
        }

        return grouped.keys.sorted().map { key in
            let dayStamps = (grouped[key] ?? []).sorted { $0.timestamp < $1.timestamp }
            return Day(date: key, stamps: dayStamps, segments: segments(for: dayStamps))
        }
    }

    /// Alternating work / rest, starting with work.
    ///
    /// An even number of stamps closes the day: `in, out` is one closed work
    /// segment, `in, lunch, back, out` is work / rest / work, all closed.
    /// An odd number leaves the last segment open, which is the normal state
    /// while you are at work and an anomaly once the day is over.
    public static func segments(for stamps: [Stamp]) -> [Segment] {
        guard !stamps.isEmpty else { return [] }

        let count = stamps.count.isMultiple(of: 2) ? stamps.count - 1 : stamps.count
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            let end = index + 1 < stamps.count ? stamps[index + 1].timestamp : nil
            return Segment(
                kind: index.isMultiple(of: 2) ? .work : .rest,
                start: stamps[index].timestamp,
                end: end
            )
        }
    }
}
