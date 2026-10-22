import XCTest
@testable import TimeCore

final class TimeCoreTests: XCTestCase {

    // MARK: - Helpers

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ string: String) -> Date {
        guard let date = LogParser.date(from: string) else {
            fatalError("Bad test date: \(string)")
        }
        return date
    }

    private func stamp(_ string: String) -> Stamp {
        Stamp(timestamp: date(string))
    }

    private func config(weeklyHours: Double = 40) -> Config {
        Config(weeklyHours: weeklyHours, workdays: [2, 3, 4, 5, 6])
    }

    // MARK: - Parsing

    func testParsesStampAndUndoLines() {
        let text = """
        2025-06-12T08:52:31+02:00|stamp
        2025-06-12T08:52:33+02:00|stamp
        2025-06-12T12:31:07+02:00|undo
        """
        let entries = LogParser.parse(text)
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].kind, .stamp)
        XCTAssertEqual(entries[1].kind, .stamp)
        XCTAssertEqual(entries[2].kind, .undo)
    }

    func testIgnoresGarbageLines() {
        let text = """
        not a line
        2025-06-12T08:52:31+02:00|unknown
        2025-06-12T08:52:31+02:00|stamp
        """
        XCTAssertEqual(LogParser.parse(text).count, 1)
    }

    func testLineFormatRoundTrips() {
        let instant = date("2025-06-12T08:52:31+02:00")
        let line = LogParser.line(
            for: instant,
            kind: .stamp,
            timeZone: TimeZone(identifier: "Europe/Zurich")!
        )
        XCTAssertEqual(line, "2025-06-12T08:52:31+02:00|stamp")
        XCTAssertEqual(LogParser.parseLine(line)?.timestamp, instant)
    }

    // MARK: - Undo and location

    func testUndoPopsTheLastStamp() {
        let entries = LogParser.parse("""
        2025-06-12T08:00:00+02:00|stamp
        2025-06-12T08:01:00+02:00|stamp
        2025-06-12T08:02:00+02:00|undo
        """)
        let stamps = EventLog.resolve(entries)
        XCTAssertEqual(stamps.count, 1)
        XCTAssertEqual(stamps.first?.timestamp, date("2025-06-12T08:00:00+02:00"))
    }

    func testUndoOnEmptyLogIsHarmless() {
        let entries = LogParser.parse("2025-06-12T08:02:00+02:00|undo")
        XCTAssertTrue(EventLog.resolve(entries).isEmpty)
    }

    // MARK: - Segments

    func testFourStampsProduceAlternatingSegments() {
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00"),
            stamp("2025-06-12T13:00:00+02:00"),
            stamp("2025-06-12T17:00:00+02:00")
        ]
        let segments = DayBuilder.segments(for: stamps)
        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments.map(\.kind), [.work, .rest, .work])
        XCTAssertEqual(segments[0].duration, 4 * 3600)
        XCTAssertEqual(segments[1].duration, 3600)
        XCTAssertEqual(segments[2].duration, 4 * 3600)
        XCTAssertTrue(segments.allSatisfy { !$0.isOpen })
    }

    func testStampsAreGroupedByLocalDay() {
        let stamps = [
            stamp("2025-06-12T23:50:00+02:00"),
            stamp("2025-06-13T00:10:00+02:00")
        ]
        let days = DayBuilder.days(from: stamps, calendar: calendar)
        XCTAssertEqual(days.count, 2)
    }

    // MARK: - Worked time and balance

    func testLunchIsDeducted() {
        let day = Day(date: date("2025-06-12T00:00:00+02:00"), stamps: [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00"),
            stamp("2025-06-12T13:00:00+02:00"),
            stamp("2025-06-12T17:00:00+02:00")
        ], segments: [])
        let dayWithSegments = Day(
            date: day.date,
            stamps: day.stamps,
            segments: DayBuilder.segments(for: day.stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(
            for: dayWithSegments,
            now: date("2025-06-13T10:00:00+02:00")
        )
        XCTAssertEqual(summary.worked, 8 * 3600)
        XCTAssertEqual(summary.target, 8 * 3600)
        XCTAssertEqual(summary.balance, 0, accuracy: 0.001)
    }

    func testOpenWorkSegmentAccruesUntilNow() {
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00"),
            stamp("2025-06-12T13:00:00+02:00")
        ]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(
            for: day,
            now: date("2025-06-12T15:00:00+02:00")
        )
        XCTAssertEqual(summary.worked, 6 * 3600)
        XCTAssertTrue(summary.isWorking)
        XCTAssertEqual(summary.leaveAt, date("2025-06-12T17:00:00+02:00"))
    }

    func testNoLeaveTimeWhenStampedOut() {
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00")
        ]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T12:30:00+02:00"))
        XCTAssertTrue(summary.isOut)
        XCTAssertFalse(summary.isWorking)
        XCTAssertNil(summary.leaveAt)
        XCTAssertEqual(summary.worked, 4 * 3600)
    }

    func testPastOpenSegmentIsNotInvented() {
        let stamps = [stamp("2025-06-12T08:00:00+02:00")]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-13T09:00:00+02:00"))
        XCTAssertEqual(summary.worked, 0)
        XCTAssertTrue(summary.anomalies.contains(.openDay))
    }

    // MARK: - Anomalies

    func testOpenDayIsNotAnAnomalyWhileWorking() {
        let stamps = [stamp("2025-06-12T08:00:00+02:00")]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T15:00:00+02:00"))
        XCTAssertFalse(summary.anomalies.contains(.openDay))
    }

    func testLongBreakIsFlagged() {
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00"),
            stamp("2025-06-12T17:00:00+02:00"),
            stamp("2025-06-12T18:00:00+02:00")
        ]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T20:00:00+02:00"))
        XCTAssertTrue(summary.anomalies.contains(.longBreak))
    }

    func testLateFirstStampIsFlagged() {
        let stamps = [
            stamp("2025-06-12T13:00:00+02:00"),
            stamp("2025-06-12T18:00:00+02:00")
        ]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T20:00:00+02:00"))
        XCTAssertTrue(summary.anomalies.contains(.lateFirstStamp))
    }

    // MARK: - Period balance

    func testWeekBalanceCountsMissingWorkdays() {
        let days = [
            Day(date: date("2025-06-09T00:00:00+02:00"), stamps: [
                stamp("2025-06-09T08:00:00+02:00"),
                stamp("2025-06-09T16:00:00+02:00")
            ], segments: []),
            Day(date: date("2025-06-10T00:00:00+02:00"), stamps: [
                stamp("2025-06-10T08:00:00+02:00"),
                stamp("2025-06-10T16:00:00+02:00")
            ], segments: []),
            Day(date: date("2025-06-11T00:00:00+02:00"), stamps: [
                stamp("2025-06-11T08:00:00+02:00"),
                stamp("2025-06-11T16:00:00+02:00")
            ], segments: [])
        ]
        var config = config()
        config.trackingStart = date("2025-06-09T00:00:00+02:00")
        let engine = BalanceEngine(config: config, calendar: calendar)
        let week = engine.weekBalance(
            for: days,
            now: date("2025-06-12T20:00:00+02:00")
        )
        // Mon–Wed are exactly on target, Thursday (12 June) has no stamps.
        XCTAssertEqual(week.balance, -8 * 3600, accuracy: 0.001)
        XCTAssertTrue(week.days.contains { $0.anomalies.contains(.missingDay) })
    }

    func testDaysBeforeTrackingStartAreIgnored() {
        var config = config()
        config.trackingStart = date("2025-06-11T00:00:00+02:00")
        let engine = BalanceEngine(config: config, calendar: calendar)
        let week = engine.weekBalance(
            for: [],
            now: date("2025-06-12T20:00:00+02:00")
        )
        // Wed and Thu only.
        XCTAssertEqual(week.days.count, 2)
        XCTAssertEqual(week.balance, -16 * 3600, accuracy: 0.001)
    }

    func testHolidayHasNoTarget() {
        var config = config()
        config.holidays = ["2025-06-12": "Holiday"]
        let engine = BalanceEngine(config: config, calendar: calendar)
        XCTAssertEqual(engine.dailyTarget(for: date("2025-06-12T00:00:00+02:00")), 0)
        XCTAssertEqual(engine.dailyTarget(for: date("2025-06-10T00:00:00+02:00")), 8 * 3600)
    }

    func testWeekendHasNoTarget() {
        let engine = BalanceEngine(config: config(), calendar: calendar)
        XCTAssertEqual(engine.dailyTarget(for: date("2025-06-14T00:00:00+02:00")), 0)
    }

    // MARK: - Rounding

    func testRoundingAppliesToPunches() {
        var config = config()
        config.roundingMinutes = 15
        let stamps = [
            stamp("2025-06-12T08:07:00+02:00"),
            stamp("2025-06-12T16:07:00+02:00")
        ]
        let day = Day(
            date: date("2025-06-12T00:00:00+02:00"),
            stamps: stamps,
            segments: DayBuilder.segments(for: stamps)
        )
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T20:00:00+02:00"))
        XCTAssertEqual(summary.worked, 8 * 3600)
    }

    // MARK: - Manual day corrections

    private var zurich: TimeZone { TimeZone(identifier: "Europe/Zurich")! }

    private func overrideLine(
        _ day: String,
        _ times: [String],
        note: String? = nil,
        at stampTime: String = "2025-06-20T20:00:00+02:00"
    ) -> String {
        LogParser.overrideLine(
            for: date(day),
            times: times.map { date($0) },
            note: note,
            timeZone: zurich,
            now: date(stampTime)
        )
    }

    func testDayOverrideReplacesRecordedStamps() {
        let text = """
        2025-06-12T08:00:00+02:00|stamp
        2025-06-12T17:00:00+02:00|stamp
        \(overrideLine("2025-06-12T00:00:00+02:00", [
            "2025-06-12T08:00:00+02:00",
            "2025-06-12T12:00:00+02:00",
            "2025-06-12T13:00:00+02:00",
            "2025-06-12T18:00:00+02:00"
        ], note: "forgot the evening tap"))
        """
        let entries = LogParser.parse(text)
        XCTAssertEqual(EventLog.resolve(entries).count, 2)

        let overrides = EventLog.overrides(entries, calendar: calendar)
        XCTAssertEqual(overrides.count, 1)

        let days = DayBuilder.days(from: EventLog.resolve(entries), overrides: overrides, calendar: calendar)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[0].stamps.count, 4)
        XCTAssertTrue(days[0].stamps.allSatisfy { $0.isManual })

        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: days[0], now: date("2025-06-13T10:00:00+02:00"))
        XCTAssertEqual(summary.worked, 9 * 3600)
        XCTAssertEqual(summary.balance, 3600, accuracy: 0.001)
        XCTAssertTrue(summary.anomalies.isEmpty)
    }

    func testClearingOverrideRevertsToRecordedStamps() {
        let text = """
        2025-06-12T08:00:00+02:00|stamp
        2025-06-12T17:00:00+02:00|stamp
        \(overrideLine("2025-06-12T00:00:00+02:00", [
            "2025-06-12T09:00:00+02:00",
            "2025-06-12T18:00:00+02:00"
        ]))
        \(LogParser.clearOverrideLine(
            for: date("2025-06-12T00:00:00+02:00"),
            timeZone: zurich,
            now: date("2025-06-20T21:00:00+02:00")
        ))
        """
        let entries = LogParser.parse(text)
        let overrides = EventLog.overrides(entries, calendar: calendar)
        XCTAssertTrue(overrides.isEmpty)

        let days = DayBuilder.days(from: EventLog.resolve(entries), overrides: overrides, calendar: calendar)
        XCTAssertEqual(days[0].stamps.count, 2)
        XCTAssertFalse(days[0].stamps.contains { $0.isManual })
    }

    func testBlankOverrideHidesRecordedStamps() {
        let text = """
        2025-06-12T08:00:00+02:00|stamp
        2025-06-12T17:00:00+02:00|stamp
        \(overrideLine("2025-06-12T00:00:00+02:00", []))
        """
        let entries = LogParser.parse(text)
        let overrides = EventLog.overrides(entries, calendar: calendar)
        XCTAssertEqual(overrides.count, 1)
        XCTAssertEqual(overrides.values.first?.times.count, 0)

        let days = DayBuilder.days(from: EventLog.resolve(entries), overrides: overrides, calendar: calendar)
        XCTAssertEqual(days.count, 1)
        XCTAssertTrue(days[0].stamps.isEmpty)
    }

    func testOverrideOnADayWithNoStampsAppears() {
        let text = overrideLine("2025-06-12T00:00:00+02:00", [
            "2025-06-12T08:00:00+02:00",
            "2025-06-12T16:00:00+02:00"
        ])
        let entries = LogParser.parse(text)
        let overrides = EventLog.overrides(entries, calendar: calendar)
        let days = DayBuilder.days(from: [], overrides: overrides, calendar: calendar)
        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[0].stamps.count, 2)
        XCTAssertTrue(days[0].stamps.allSatisfy { $0.isManual })
    }

    func testLastOverrideWins() {
        let text = """
        \(overrideLine("2025-06-12T00:00:00+02:00", ["2025-06-12T08:00:00+02:00", "2025-06-12T16:00:00+02:00"], at: "2025-06-20T20:00:00+02:00"))
        \(overrideLine("2025-06-12T00:00:00+02:00", ["2025-06-12T09:00:00+02:00", "2025-06-12T17:00:00+02:00"], at: "2025-06-20T21:00:00+02:00"))
        """
        let overrides = EventLog.overrides(LogParser.parse(text), calendar: calendar)
        let times = overrides.values.first?.times ?? []
        XCTAssertEqual(times.count, 2)
        XCTAssertEqual(times.first, date("2025-06-12T09:00:00+02:00"))
    }

    func testOverrideNoteIsKept() {
        let text = overrideLine(
            "2025-06-12T00:00:00+02:00",
            ["2025-06-12T08:00:00+02:00", "2025-06-12T16:00:00+02:00"],
            note: "doctor in the morning"
        )
        let overrides = EventLog.overrides(LogParser.parse(text), calendar: calendar)
        XCTAssertEqual(overrides.values.first?.note, "doctor in the morning")
    }

    // MARK: - Write planning

    func testStampWithoutOverrideWritesAStampLine() {
        let lines = WritePlanner.stampLines(
            at: date("2025-06-12T09:00:00+02:00"),
            entries: [],
            calendar: calendar
        )
        XCTAssertEqual(lines, ["2025-06-12T09:00:00+02:00|stamp"])
    }

    func testStampOnEditedDayExtendsTheOverride() {
        let text = """
        2025-06-12T08:00:00+02:00|stamp
        2025-06-12T17:00:00+02:00|stamp
        2025-06-12T18:00:00+02:00|day|2025-06-12|08:30|17:30|note=corrected
        """
        let instant = date("2025-06-12T18:30:00+02:00")
        let lines = WritePlanner.stampLines(
            at: instant,
            entries: LogParser.parse(text),
            calendar: calendar
        )
        XCTAssertEqual(
            lines,
            ["2025-06-12T18:30:00+02:00|day|2025-06-12|08:30|17:30|18:30|note=corrected"]
        )

        let entries = LogParser.parse(text + "\n" + lines[0])
        let overrides = EventLog.overrides(entries, calendar: calendar)
        XCTAssertEqual(overrides.values.first?.times.count, 3)

        let days = DayBuilder.days(from: EventLog.resolve(entries), overrides: overrides, calendar: calendar)
        let engine = BalanceEngine(config: config(), calendar: calendar)
        let summary = engine.summary(for: days[0], now: instant)
        XCTAssertTrue(summary.isWorking)
    }

    func testUndoOnEditedDayRemovesTheLastTime() {
        let text = "2025-06-12T18:00:00+02:00|day|2025-06-12|08:30|12:00|13:00|17:30"
        let instant = date("2025-06-12T18:05:00+02:00")
        let lines = WritePlanner.undoLines(at: instant, entries: LogParser.parse(text), calendar: calendar)
        XCTAssertEqual(lines, ["2025-06-12T18:05:00+02:00|day|2025-06-12|08:30|12:00|13:00"])
    }

    func testUndoOnSingleTimeOverrideClearsIt() {
        let text = "2025-06-12T18:00:00+02:00|day|2025-06-12|08:30"
        let instant = date("2025-06-12T18:05:00+02:00")
        let lines = WritePlanner.undoLines(at: instant, entries: LogParser.parse(text), calendar: calendar)
        XCTAssertEqual(lines, ["2025-06-12T18:05:00+02:00|dayclear|2025-06-12"])
    }

    // MARK: - Lunch policy

    func testStandardLunchIsDeductedWhenNoBreakRecorded() {
        var config = config()
        config.standardLunchMinutes = 60
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T17:00:00+02:00")
        ]
        let day = Day(date: date("2025-06-12T00:00:00+02:00"), stamps: stamps, segments: DayBuilder.segments(for: stamps))
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-13T10:00:00+02:00"))
        XCTAssertEqual(summary.present, 9 * 3600)
        XCTAssertEqual(summary.lunchDeduction, 3600)
        XCTAssertEqual(summary.worked, 8 * 3600)
        XCTAssertEqual(summary.balance, 0, accuracy: 0.001)
    }

    func testRecordedLunchReplacesStandardLunch() {
        var config = config()
        config.standardLunchMinutes = 60
        let stamps = [
            stamp("2025-06-12T08:00:00+02:00"),
            stamp("2025-06-12T12:00:00+02:00"),
            stamp("2025-06-12T12:30:00+02:00"),
            stamp("2025-06-12T17:00:00+02:00")
        ]
        let day = Day(date: date("2025-06-12T00:00:00+02:00"), stamps: stamps, segments: DayBuilder.segments(for: stamps))
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-13T10:00:00+02:00"))
        XCTAssertEqual(summary.present, 8.5 * 3600)
        XCTAssertEqual(summary.lunchDeduction, 0)
        XCTAssertEqual(summary.worked, 8.5 * 3600)
        XCTAssertEqual(summary.balance, 1800, accuracy: 0.001)
    }

    func testShortPresenceSkipsStandardLunch() {
        var config = config()
        config.standardLunchMinutes = 60
        let stamps = [
            stamp("2025-06-12T09:00:00+02:00"),
            stamp("2025-06-12T09:30:00+02:00")
        ]
        let day = Day(date: date("2025-06-12T00:00:00+02:00"), stamps: stamps, segments: DayBuilder.segments(for: stamps))
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-13T10:00:00+02:00"))
        XCTAssertEqual(summary.present, 1800)
        XCTAssertEqual(summary.lunchDeduction, 0)
        XCTAssertEqual(summary.worked, 1800)
    }

    func testStandardLunchShiftsLeaveTime() {
        var config = config()
        config.standardLunchMinutes = 60
        let stamps = [stamp("2025-06-12T08:00:00+02:00")]
        let day = Day(date: date("2025-06-12T00:00:00+02:00"), stamps: stamps, segments: DayBuilder.segments(for: stamps))
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-12T10:00:00+02:00"))
        XCTAssertEqual(summary.present, 2 * 3600)
        XCTAssertEqual(summary.worked, 3600)
        XCTAssertEqual(summary.leaveAt, date("2025-06-12T17:00:00+02:00"))
    }

    func testStandardLunchDoesNotApplyOnWeekends() {
        var config = config()
        config.standardLunchMinutes = 60
        let stamps = [
            stamp("2025-06-14T08:00:00+02:00"),
            stamp("2025-06-14T17:00:00+02:00")
        ]
        let day = Day(date: date("2025-06-14T00:00:00+02:00"), stamps: stamps, segments: DayBuilder.segments(for: stamps))
        let engine = BalanceEngine(config: config, calendar: calendar)
        let summary = engine.summary(for: day, now: date("2025-06-15T10:00:00+02:00"))
        XCTAssertEqual(summary.present, 9 * 3600)
        XCTAssertEqual(summary.lunchDeduction, 0)
        XCTAssertEqual(summary.worked, 9 * 3600)
    }

    func testConfigDecodesWithoutLunchField() throws {
        let json = #"{"weeklyHours":40,"workdays":[2,3,4,5,6],"roundingMinutes":0,"holidays":{}}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        XCTAssertEqual(config.weeklyHours, 40)
        XCTAssertEqual(config.standardLunchMinutes, 0)
    }

    // MARK: - Formatting

    func testFormatting() {
        XCTAssertEqual(Format.duration(8 * 3600 + 12 * 60), "8h 12m")
        XCTAssertEqual(Format.duration(42 * 60), "42m")
        XCTAssertEqual(Format.signedDuration(-42 * 60), "-42m")
        XCTAssertEqual(Format.signedDuration(3600 + 5 * 60), "+1h 05m")
        XCTAssertEqual(
            Format.time(date("2025-06-12T08:52:00+02:00"), timeZone: TimeZone(identifier: "Europe/Zurich")!),
            "08:52"
        )
    }
}
