import Foundation
import Logging
import TrailBlazer

// The formatter used for the timestamp when writing messages to the log file
private let _formatter: DateFormatter = {
    let fmtr: DateFormatter = DateFormatter()
    fmtr.dateFormat = "MMM dd, yyyy HH:mm:ss.SSS ZZZZZ"
    fmtr.locale = Locale(identifier: "en_US_POSIX")
    fmtr.timeZone = TimeZone(identifier: "UTC")
    return fmtr
}()

public protocol FileHandler: LogHandler {
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    var encoding: String.Encoding { get set }

    var label: String { get }
}

public extension FileHandler {
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        return metadata.isEmpty ? metadata.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }

    internal func buildMessage(level: Logger.Level,
                               message: Logger.Message,
                               metadata: Logger.Metadata?,
                               file: String, function: String, line: UInt) -> Data {
        let prettyMetadata = metadata?.isEmpty ?? true
            ? prettify(self.metadata)
            : prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))

        let timestamp = _formatter.string(from: Date())
        var message: String = "\(timestamp) [\(level)] \(label): \(prettyMetadata.map { " \($0)" } ?? "") \(message)\n"
        if level <= .debug {
            message += " (\(file):\(line) \(function)"
        }

        guard let data = message.data(using: encoding) else {
            fatalError("Message '\(message)' contains characters not convertible using \(encoding) encoding")
        }

        return data
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { return metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
}

public protocol ConstantStreamFileHandler: FileHandler {
    /// An opened file that can be written to
    var stream: FileStream { get }
}

public extension ConstantStreamFileHandler {
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             file: String, function: String, line: UInt) {
        let data = buildMessage(level: level,
                                message: message,
                                metadata: metadata,
                                file: file, function: function, line: line)

        do {
            try stream.write(data)
        } catch {
            fatalError("Failed to write log message")
        }
    }
}
