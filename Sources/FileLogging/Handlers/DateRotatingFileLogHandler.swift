import Foundation
import Logging
import TrailBlazer

public struct DateRotatingFileLogHandler: RotatingFileLogHandler {
    private let filename: String
    private let fileExtension: String
    public let logFile: FilePath
    public let options: DateRotateOption
    public var encoding: String.Encoding
    public let label: String
    public var logLevel = Logger.Level.info
    public var metadata = Logger.Metadata()
    private let formatter: DateFormatter
    private let range: DateRangeWrapper
    public let max: UInt?

    public init(label: String,
                opened file: FileStream,
                encoding: String.Encoding,
                options: DateRotateOption,
                max: UInt? = nil) {
        self.label = label
        self.encoding = encoding
        self.options = options
        self.max = max
        let path = file.path.absolute ?? file.path
        logFile = path
        let ext = path.extension ?? ""
        fileExtension = ext.isEmpty ? "" : ".\(ext)"
        filename = String((path.lastComponent !! "Found empty path").dropLast(fileExtension.count))
        let formatter = DateFormatter()
        formatter.dateFormat = options.format
        self.formatter = formatter
        range = .init(options.range())
        stream = file
    }

    public func rotate(message _: Data) -> String? {
        guard !range.contains(Date()) else { return nil }

        defer { range.update(to: options.range()) }

        return "\(filename)-\(formatter.string(from: range.lowerBound))\(fileExtension)"
    }

    public func cleanup(max: UInt) {
        var existingLogs: [FilePath]
        do {
            existingLogs = try glob(pattern: "\(filename)-*\(fileExtension)").matches.files
        } catch {
            fatalError("Failed to glob for current log files")
        }

        existingLogs.sort { (log1: FilePath, log2: FilePath) -> Bool in
            let date1 = date(from: log1)
            let date2 = date(from: log2)
            return date1 > date2
        }

        while UInt(existingLogs.count) > max {
            var oldestFile = existingLogs.popLast()
            do {
                try oldestFile?.delete()
            } catch {
                fatalError("Failed to delete oldest log \(oldestFile!)")
            }
        }
    }

    private func date(from file: FilePath) -> Date {
        let dateString = String(file.lastComponent!.dropLast(fileExtension.count).dropFirst(filename.count + 1))
        return formatter.date(from: dateString) !! "Malformed log file date format '\(dateString)' for \(file)"
    }
}

private final class DateRangeWrapper {
    private var storage: Range<Date>

    fileprivate var lowerBound: Date { return storage.lowerBound }
    private var upperBound: Date { return storage.upperBound }

    fileprivate init(_ range: Range<Date>) {
        storage = range
    }

    fileprivate func update(to range: Range<Date>) {
        storage = range
    }

    fileprivate func contains(_ date: Date) -> Bool {
        return storage.contains(date)
    }
}
