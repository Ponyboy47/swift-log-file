import Logging
import TrailBlazer

public struct FileLogHandler: ConstantStreamFileHandler {
    public let stream: FileStream
    public var encoding: String.Encoding
    public let label: String
    public var logLevel = Logger.Level.info
    public var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            prettyMetadata = prettify(metadata)
        }
    }

    public init(label: String, opened file: FileStream, encoding: String.Encoding) {
        self.label = label
        stream = file
        self.encoding = encoding
    }
}
