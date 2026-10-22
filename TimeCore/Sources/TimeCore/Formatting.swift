import Foundation

public enum Format {

    /// "8h 12m", "45m", "0m"
    public static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int((abs(interval) / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }

    /// "+42m", "-1h 05m", "0m"
    public static func signedDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int((abs(interval) / 60).rounded())
        let sign = interval < -30 ? "-" : (interval > 30 ? "+" : "")
        let body: String
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            body = "\(minutes)m"
        } else if minutes == 0 {
            body = "\(hours)h"
        } else {
            body = "\(hours)h \(String(format: "%02d", minutes))m"
        }
        return sign + body
    }

    /// "08:52" in the calendar's time zone.
    public static func time(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// "Thu 12 Jun"
    public static func dayLabel(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    /// "12 June 2025"
    public static func longDayLabel(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
