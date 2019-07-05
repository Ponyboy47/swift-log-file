import Logging
import TrailBlazer

public struct FileLogHandler: ConstantStreamFileHandler {
    /// An opened file that can be written to
    public let stream: FileStream

    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    /// The label for the handler
    public let label: String
    /// The minimum level allowed for levels to be written to file
    public var logLevel = Logger.Level.info
    /// Special Logger metadata
    public var metadata = Logger.Metadata()

    public init(label: String, opened file: FileStream, encoding: String.Encoding) {
        self.label = label
        stream = file
        self.encoding = encoding
    }
}
