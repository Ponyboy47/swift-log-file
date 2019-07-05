import Foundation
import Logging
import TrailBlazer

private let calendar = Calendar.current

private func currentHour() -> Date {
    return calendar.date(bySetting: .minute,
                         value: 0,
                         of: calendar.date(bySetting: .minute,
                                           value: 0,
                                           of: Date())!)!
}

private var currentStreams = [RotatingFileLogHandler: (stream: FileStream, opened: Date)]()
public struct RotatingFileLogHandler: FileHandler, Hashable {
    private let basePath: FilePath
    private let options: RotateOptions
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding
    /// The label for the handler
    public let label: String
    /// The minimum level allowed for levels to be written to file
    public var logLevel = Logger.Level.info
    /// Special Logger metadata
    public var metadata = Logger.Metadata()

    public init(label: String, opened file: FileStream, encoding: String.Encoding, options: RotateOptions) {
        self.label = label
        self.encoding = encoding
        self.options = options
        basePath = file.path
        currentStreams[self] = (stream: file, opened: currentHour())
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(basePath)
    }

    private func getStream(message: Data) -> FileStream {
        var new: FileStream?
        for option in options.storage.sorted() {
            switch option.type {
            case .date:
                guard new == nil else { continue }
                new = dateRotatedStream(max: option.value)
            case .size:
                guard new == nil else { continue }
                new = sizeRotatedStream(message: message, max: option.value)
            case .maxOverall:
                guard new != nil else { continue }
                maxFilesCleanup(max: option.value)
            case .maxPerDatePeriod:
                guard new != nil else { continue }
                maxFilesPerPeriodCleanup(max: option.value)
            case .none:
                continue
            }
        }

        return newOrCurrentStream(new)
    }

    private func newOrCurrentStream(_ new: FileStream?) -> FileStream {
        guard let newStream = new else { return currentStreams[self]!.stream }

        currentStreams[self] = (stream: newStream, opened: currentHour())
        return newStream
    }

    private func dateRotatedStream(max hours: UInt64) -> FileStream? {
        let openedAt = currentStreams[self]!.opened
        // Make sure the time between the original opened hour and the current hour is greater than the allowed hours or
        // just return nil
        let distance = UInt64(calendar.dateComponents([.hour], from: openedAt, to: Date()).hour ?? 0)
        guard distance >= hours else { return nil }

        // rotate and return the newly opened stream
    }

    private func sizeRotatedStream(message: Data, max size: UInt64) -> FileStream? {
        // Make sure the current file size + the new message would exceed the allowed size or just return nil
        guard basePath.size + message.count >= size else { return nil }

        // rotate and return the newly opened stream
    }

    private func maxFilesCleanup(max _: UInt64) {}

    private func maxFilesPerPeriodCleanup(max _: UInt64) {}

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    file: String, function: String, line: UInt) {
        let message = buildMessage(level: level,
                                   message: message,
                                   metadata: metadata,
                                   file: file, function: function, line: line)
        let stream = getStream(message: message)
    }
}
