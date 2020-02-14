import Foundation
import Logging
import Pathman

public struct SizeRotatingFileLogHandler: RotatingFileLogHandler {
    private let filename: String
    private let fileExtension: String
    public let logFile: FilePath
    public let options: UInt64
    public var maxSize: UInt64 { return options }
    public var encoding: String.Encoding
    public let label: String
    public var logLevel = Logger.Level.info
    public var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            prettyMetadata = prettify(metadata)
        }
    }

    public let max: UInt?

    public init(label: String,
                opened stream: FileStream,
                encoding: String.Encoding,
                options: UInt64,
                max: UInt? = nil) {
        self.label = label
        self.encoding = encoding
        self.options = options
        self.max = max
        let path = stream.path.absolute ?? stream.path
        logFile = path
        let ext = path.extension ?? ""
        fileExtension = ext.isEmpty ? "" : ".\(ext)"
        filename = String((path.lastComponent !! "Found empty path").dropLast(fileExtension.count))
        self.stream = stream
        unusedStreams.remove(stream)
        currentStreams[self] = stream
    }

    public func rotate(message: Data) -> String? {
        let msgSize = message.count
        guard logFile.size + msgSize > maxSize else { return nil }

        guard msgSize <= maxSize else {
            fatalError("Message is larger than maximum byte size allowed per file rotation (\(msgSize) > \(maxSize))")
        }

        return "\(filename)\(fileExtension).1"
    }

    public func cleanup(max: UInt) {
        var maxRotationIndex: UInt = 0
        let rotatedLogs = getRotatedLogs()
        for log in rotatedLogs {
            guard let ext = log.extension, let rotationIndex = UInt(ext) else { continue }
            maxRotationIndex = Swift.max(rotationIndex, maxRotationIndex)
        }

        for index in (1..<maxRotationIndex).reversed() {
            guard var log = rotatedLogs.first(where: { $0.extension ?? "" == "\(index)" }) else {
                fatalError("Could not locate rotated log with index number: \(index)")
            }

            if index < max {
                let rotatedFilename = "\(log.lastComponentWithoutExtension!).\(index + 1)"
                do {
                    try log.rename(to: rotatedFilename)
                } catch {
                    fatalError("Failed to rotate log file from \(log.lastComponent!) to \(rotatedFilename)")
                }
            } else {
                do {
                    try log.delete()
                } catch {
                    fatalError("Failed to delete log: \(log)")
                }
            }
        }
    }

    private func getRotatedLogs() -> [FilePath] {
        do {
            return try glob(pattern: "\(filename)\(fileExtension).*").matches.files
        } catch {
            fatalError("Failed to glob for rotated log files")
        }
    }
}

public extension UInt64 {
    var kilobytes: UInt64 {
        return self * 1024
    }

    var megabytes: UInt64 {
        return self * 1024 * 1024
    }

    var gigabytes: UInt64 {
        return self * 1024 * 1024 * 1024
    }
}
