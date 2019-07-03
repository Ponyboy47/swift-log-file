import Logging
import TrailBlazer

public struct FileLogHandler: FileHandler {
    // swiftlint:disable identifier_name

    /// An opened file that can be written to
    public var _stream: FileStream!

    // swiftlint:enable identifier_name

    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    /// The label for the handler
    public var label: String
    /// The minimum level allowed for levels to be written to file
    public var logLevel = Logger.Level.info
    /// Special Logger metadata
    public var metadata = Logger.Metadata()

    public init(label: String, opened file: FileStream, encoding: String.Encoding) {
        self.label = label
        _stream = file
        self.encoding = encoding
    }
}
