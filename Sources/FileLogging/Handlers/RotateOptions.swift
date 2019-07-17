import Foundation

private let calendar = Calendar.current
private let secondsPerMinute = UInt(calendar.maximumRange(of: .second)?.upperBound ?? 60)
private let minutesPerHour = UInt(calendar.maximumRange(of: .minute)?.upperBound ?? 60)
private let hoursPerDay = UInt(calendar.maximumRange(of: .hour)?.upperBound ?? 24)
private let daysPerWeek = UInt((calendar.maximumRange(of: .weekday)?.upperBound ?? 8) - 1)
private let secondsPerDay = secondsPerMinute * minutesPerHour * hoursPerDay

private extension Calendar {
    func startOfMinute(for date: Date) -> Date {
        return self.date(bySetting: .minute,
                         value: 0,
                         of: date)!
    }

    func startOfHour(for date: Date) -> Date {
        return self.date(bySetting: .minute,
                         value: 0,
                         of: startOfMinute(for: date))!
    }

    func startOfWeek(for date: Date) -> Date {
        let weekday = component(.weekday, from: date)
        guard weekday == 1 else {
            return startOfDay(for: date)
        }

        let secondsToWeekStart = secondsPerDay * (daysPerWeek - UInt(weekday))
        return startOfDay(for: date - TimeInterval(secondsToWeekStart))
    }

    func startOfMonth(for date: Date) -> Date {
        return self.date(bySetting: .day,
                         value: 1,
                         of: startOfDay(for: date))!
    }

    func startOfYear(for date: Date) -> Date {
        return self.date(bySetting: .month,
                         value: 1,
                         of: startOfMonth(for: date))!
    }

    func nextStartOfMinute(from date: Date) -> Date {
        return self.date(byAdding: .minute, value: 1, to: startOfMinute(for: date))!
    }

    func nextStartOfHour(from date: Date) -> Date {
        return self.date(byAdding: .hour, value: 1, to: startOfHour(for: date))!
    }

    func nextStartOfDay(from date: Date) -> Date {
        return self.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
    }

    func nextStartOfWeek(from date: Date) -> Date {
        return self.date(byAdding: .day, value: Int(daysPerWeek), to: startOfWeek(for: date))!
    }

    func nextStartOfMonth(from date: Date) -> Date {
        return self.date(byAdding: .month, value: 1, to: startOfMonth(for: date))!
    }

    func nextStartOfYear(from date: Date) -> Date {
        return self.date(byAdding: .year, value: 1, to: startOfYear(for: date))!
    }
}

public enum DateRotateOption: Hashable {
    case seconds(UInt)
    case minutes(UInt)
    case hours(UInt)
    case days(UInt)
    case weeks(UInt)
    case months(UInt)
    case years(UInt)

    public static let hourly = DateRotateOption.hours(1)
    public static let daily = DateRotateOption.days(1)
    public static let weekly = DateRotateOption.weeks(1)
    public static let monthly = DateRotateOption.months(1)
    public static let yearly = DateRotateOption.years(1)

    var format: String {
        switch self {
        case .seconds: return "yyyy-mm-dd:HH:MM:SS"
        case .minutes, .hours: return "yyyy-mm-dd:HH:MM"
        case .days, .weeks: return "yyyy-mm-dd"
        case .months: return "yyyy-mm"
        case .years: return "yyyy"
        }
    }

    func range() -> Range<Date> {
        let start: Date
        let end: Date

        switch self {
        case .seconds(let seconds):
            start = Date()
            end = calendar.date(byAdding: .second, value: Int(seconds), to: start)!
        case .minutes(let minutes):
            start = calendar.startOfMinute(for: Date())
            end = calendar.date(byAdding: .minute, value: Int(minutes), to: start)!
        case .hours(let hours):
            start = calendar.startOfHour(for: Date())
            end = calendar.date(byAdding: .hour, value: Int(hours), to: start)!
        case .days(let days):
            start = calendar.startOfDay(for: Date())
            end = calendar.date(byAdding: .day, value: Int(days), to: start)!
        case .weeks(let weeks):
            start = calendar.startOfWeek(for: Date())
            end = calendar.date(byAdding: .day, value: Int(weeks * daysPerWeek), to: start)!
        case .months(let months):
            start = calendar.startOfMonth(for: Date())
            end = calendar.date(byAdding: .month, value: Int(months), to: start)!
        case .years(let years):
            start = calendar.startOfYear(for: Date())
            end = calendar.date(byAdding: .year, value: Int(years), to: start)!
        }

        return start..<end
    }
}

public extension BinaryInteger {
    private var uint: UInt { return UInt(self) }
    var seconds: DateRotateOption { return .seconds(uint) }
    var minutes: DateRotateOption { return .minutes(uint) }
    var hours: DateRotateOption { return .hours(uint) }
    var days: DateRotateOption { return .days(uint) }
    var weeks: DateRotateOption { return .weeks(uint) }
    var months: DateRotateOption { return .months(uint) }
    var years: DateRotateOption { return .years(uint) }
}
