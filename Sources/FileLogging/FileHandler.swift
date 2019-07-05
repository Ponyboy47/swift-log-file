import Foundation
import Logging
import TrailBlazer

// Create a queue used to flush the buffers with the utility qos since that is good for system I/O taks
private let bufferQueue = DispatchQueue(label: "com.ponyboy47.fileloghandler", qos: .utility)

// A set of buffers that contains the stream and the messages to write to it
// NOTE: This is global because the LogHandler is a struct and so a buffer variable could not be cannot be modified in
// the log function
private var loggingBuffers: [FileStream: [Data]] = [:]

// Iterates through all the streams in the buffer and tries to flush all leftover messages, then schedules another
// execution for 60 seconds after completion (assuming there are things that still failed to be flushed)
private func flushBuffers() {
    // Go through all the messages for all the streams in the buffer
    for (stream, var messages) in loggingBuffers {
        // Go through all the messages for the stream
        var idx = 0
        while idx < messages.count {
            let message = messages[idx]
            // If the message succeeds to be written, then remove it from the array of messages and don't increment the
            // current index (since there's no need to)
            guard (try? stream.write(message)) == nil else {
                messages.remove(at: idx)
                continue
            }

            // If the message failed again then leave it in the messages array and hop over it
            idx += 1
        }

        // Update the current stream's messages array
        loggingBuffers[stream] = messages
    }

    // Remove any streams that successfully flushed all of their messages
    loggingBuffers = loggingBuffers.filter { !$0.value.isEmpty }

    // Flush the buffers every 60 seconds until they're empty
    if !loggingBuffers.isEmpty {
        bufferQueue.asyncAfter(deadline: .now() + 60) { flushBuffers() }
    }
}

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

    internal func writeOrQueueMessage(to stream: FileStream, _ data: Data) {
        let wasEmpty = loggingBuffers.isEmpty
        if !loggingBuffers.keys.contains(stream) {
            do {
                try stream.write(data)
            } catch {
                loggingBuffers[stream] = [data]
            }
        } else {
            loggingBuffers[stream]!.append(data)
        }

        // If the buffers were empty, but aren't any more then begin flushing them every 60 seconds
        if wasEmpty, !loggingBuffers.isEmpty {
            bufferQueue.asyncAfter(deadline: .now() + 60) { flushBuffers() }
        }
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

        writeOrQueueMessage(to: stream, data)
    }
}
