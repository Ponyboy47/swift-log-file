import Logging
import TrailBlazer

public enum RotateOptions: OptionSet {
    public enum DateRotateOption: RawRepresentable {
        public var rawValue: UInt64 {
            switch self {
            case .hourly: return UInt64(60 * 60)
            case .daily: return UInt64(60 * 60 * 24)
            case .weekly: return UInt64(60 * 60 * 24 * 7)
            case .monthly: return UInt64(60 * 60 * 24 * 30)
            case .yearly: return UInt64(60 * 60 * 24 * 365)
            case .seconds(let seconds): return UInt64(seconds)
            }
        }

        case hourly
        case daily
        case weekly
        case monthly
        case yearly
        case seconds(Int64)

        public init(rawValue: UInt64) {
            if rawValue == 60 * 60 {
                self = .hourly
            } else if rawValue == 60 * 60 * 24 {
                self = .daily
            } else if rawValue == 60 * 60 * 24 * 7 {
                self = .weekly
            } else if rawValue == 60 * 60 * 24 * 30 {
                self = .monthly
            } else if rawValue == 60 * 60 * 24 * 365 {
                self = .yearly
            } else {
                let intValue = Int64(rawValue)
                self = .seconds(intValue < 0 ? Int64.max : intValue)
            }
        }
    }

    public var rawValue: UInt64 {
        switch self {
        case .date(let seconds): return seconds.rawValue
        case .size(let bytes): return UInt64.max & UInt64(bytes)
        }
    }

    case date(DateRotateOption)
    case size(Int64)

    public init(rawValue: UInt64) {
        if rawValue > Int64.max {
            self = .size(Int64.max & Int64(rawValue))
        } else {
            self = .date(DateRotateOption(rawValue: rawValue))
        }
    }
}

public struct RotatingFileLogHandler: FileHandler {
    // swiftlint:disable identifier_name

    /// An opened file that can be written to
    public var _stream: FileStream!

    // swiftlint:enable identifier_name

    private var options: RotateOptions

    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    /// The label for the handler
    public var label: String
    /// The minimum level allowed for levels to be written to file
    public var logLevel = Logger.Level.info
    /// Special Logger metadata
    public var metadata = Logger.Metadata()

    public init(label: String, opened file: FileStream, encoding: String.Encoding, options: RotateOptions) {
        self.label = label
        _stream = file
        self.encoding = encoding
        self.options = options
    }
}
