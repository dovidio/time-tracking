import Foundation

/// Applies the lines chosen by `WritePlanner` to the log.
enum StampWriter {
    static func stamp(at instant: Date, store: LogStore, calendar: Calendar) throws {
        for line in WritePlanner.stampLines(at: instant, entries: store.load(), calendar: calendar) {
            try store.append(line)
        }
    }

    static func undo(at instant: Date, store: LogStore, calendar: Calendar) throws {
        for line in WritePlanner.undoLines(at: instant, entries: store.load(), calendar: calendar) {
            try store.append(line)
        }
    }
}
