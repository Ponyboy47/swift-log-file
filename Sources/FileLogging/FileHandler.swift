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

/// A LogHandler that writes messages to a file
public protocol FileHandler: LogHandler {
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    var encoding: String.Encoding { get set }

    /// A beautiful representation of the LogHandler's metadata
    var prettyMetadata: String? { get }

    /// A label associated with the LogHandler
    var label: String { get }
}

public extension FileHandler {
    /**
     Converts Logger.Metadata into a beautiful space separated list of key=value strings

     - Parameter metadata: The metadata to beautify

     - Returns: A String of beautified metadata or nil if empty
     **/
    func prettify(_ metadata: Logger.Metadata) -> String? {
        return metadata.isEmpty ? metadata.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }

    /**
     Generates an encoded Data object of the message which will be written to the file

     - Parameters:
       - level: The level of the message being logged
       - message: The message being logged
       - metadata: Metadata attached to the log
       - file: The file from which the message is being logged
       - function: The function where the log message is contained
       - line: The line from which the message is being logged

     - Returns: An encoded Data object of the exact message to be written to the file
     **/
    internal func buildMessage(level: Logger.Level,
                               message: Logger.Message,
                               metadata: Logger.Metadata?,
                               file: String, function: String, line: UInt) -> Data {
        // Generate a pretty metadata string
        let prettyMetadata = metadata?.isEmpty ?? true
            ? self.prettyMetadata
            : prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))

        // Generate the timestamp to use
        let timestamp = _formatter.string(from: Date())
        // Build the message string
        var message: String = "\(timestamp) [\(level)] \(label): \(prettyMetadata.map { " \($0)" } ?? "") \(message)"

        // If the message is debug-related, append the location from which the logger was called
        if level <= .debug {
            message += " (\(file):\(line) \(function))"
        }
        // Messages need to end in a newline
        message += "\n"

        // Convert the string message into data that can be written to a FileStream
        guard let data = message.data(using: encoding) else {
            fatalError("Message '\(message)' contains characters not convertible using \(encoding) encoding")
        }

        // Return the data
        return data
    }

    /**
     Grabs a metadata value by key

     - Parameter metadataKey: The key whose value should be set/returned from the metadata

     - Returns: The value associated with the metadataKey or nil if it doesn't exist in the metadata
     **/
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { return metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
}

/// A FileHandler that writes to a stream that never changes
public protocol ConstantStreamFileHandler: FileHandler {
    /// An opened file that can be written to
    var stream: FileStream { get }
}

public extension ConstantStreamFileHandler {
    /**
     Write a message to the log file

     - Parameters:
       - level: The level of the message being logged
       - message: The message being logged
       - metadata: Metadata attached to the log
       - file: The file from which the message is being logged
       - function: The function where the log message is contained
       - line: The line from which the message is being logged

     - Note: Crashes the program if the write fails
     **/
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
