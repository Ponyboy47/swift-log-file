import Foundation
import Logging
import TrailBlazer

private var currentStreams = [AnyHashable: FileStream]()

public protocol RotatingFileLogHandler: FileHandler, Hashable {
    associatedtype RotateOptions: Hashable
    /// The actual filepath where logs will be written to
    var logFile: FilePath { get }
    /// Options for determining when files should be rotated and the max number of files to keep around
    var options: RotateOptions { get }
    /// The maximum number of rotations to allow before deleting extras
    var max: UInt? { get }

    init(label: String, opened file: FileStream, encoding: String.Encoding, options: RotateOptions, max: UInt?)

    func rotate(message data: Data) -> String?
    func cleanup(max: UInt)
}

extension RotatingFileLogHandler {
    public var stream: FileStream? {
        get { return currentStreams[AnyHashable(self)] }
        nonmutating set { currentStreams[AnyHashable(self)] = newValue }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(logFile)
    }

    /// Closes the current stream, rotates the file, then opens a new stream
    private func rotateLog(to rotatedFilename: String) {
        do {
            try currentStreams[self]!.close()
        } catch {
            fatalError("Failed to close opened file stream to log \(logFile)")
        }

        do {
            var tmp = logFile
            try tmp.rename(to: rotatedFilename)
        } catch {
            fatalError("Failed to rotate log file from \(logFile.lastComponent!) to \(rotatedFilename)")
        }

        do {
            stream = try logFile.open(mode: "a")
        } catch {
            fatalError("Failed to open new log \(logFile)")
        }
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    file: String, function: String, line: UInt) {
        let data = buildMessage(level: level,
                                message: message,
                                metadata: metadata,
                                file: file, function: function, line: line)

        if let newName = rotate(message: data) {
            if let max = self.max {
                cleanup(max: max)
            }
            rotateLog(to: newName)
        }

        guard let stream = self.stream else {
            fatalError("No file stream opened for writing")
        }

        do {
            try stream.write(data)
        } catch {
            fatalError("Failed to write log message")
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.label == rhs.label && lhs.logFile == rhs.logFile && lhs.options == rhs.options && lhs.max == rhs.max
    }
}
