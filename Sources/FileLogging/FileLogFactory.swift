import TrailBlazer

var unusedStreams = Set<FileStream>()

// swiftlint:disable type_name
public class _FileLogFactory {
    // swiftlint:enable type_name

    /// The parent directory in which log files will be written by their label name
    fileprivate let parent: DirectoryPath?
    /// An opened file that can be written to which should use line buffered writes
    fileprivate let stream: FileStream?
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    /// The encoding to default to when creating file-based logs from a factory
    public static var defaultEncoding: String.Encoding = .utf8

    public convenience init(path: String,
                            encoding: String.Encoding = _FileLogFactory.defaultEncoding) {
        if let file = FilePath(path) {
            self.init(file: file, encoding: encoding)
        } else if let dir = DirectoryPath(path) {
            self.init(directory: dir, encoding: encoding)
        } else {
            fatalError("Path '\(path)' must be either a file, directory, or nonexistent path (treated as a new file)")
        }
    }

    public convenience init(file: FilePath,
                            encoding: String.Encoding = _FileLogFactory.defaultEncoding) {
        // Ensure log files have the '.log' extension
        // var file = file
        // if (file.extension ?? "") != "log" {
        //     file = FilePath("\(file.absolute?.string ?? file.string).log")
        // }

        do {
            // Open the file for appending and create it if it doesn't exist
            try self.init(opened: file.open(mode: "a"), encoding: encoding)
        } catch {
            fatalError("Failed to open \(file) with error \(type(of: error)).\(error)")
        }
    }

    public init(directory: DirectoryPath,
                encoding: String.Encoding = _FileLogFactory.defaultEncoding) {
        parent = directory
        stream = nil
        self.encoding = encoding
    }

    fileprivate init(opened stream: FileStream,
                     encoding: String.Encoding = _FileLogFactory.defaultEncoding) {
        parent = nil
        self.stream = stream
        self.encoding = encoding
        unusedStreams.insert(stream)
        do {
            try stream.setBuffer(mode: .line)
        } catch {
            fatalError("Unable to use line buffered writes")
        }
    }

    deinit {
        unusedStreams.forEach { try? $0.close() }
        currentStreams.forEach { try? $0.value.close() }
    }
}

public final class FileLogHandlerFactory: _FileLogFactory {
    public func makeFileLogHandler(label: String) -> FileLogHandler {
        guard stream == nil else {
            return .init(label: label, opened: stream!, encoding: encoding)
        }

        let path = parent! + "\(label).log"
        guard let file = FilePath(path.absolute ?? path) else {
            fatalError("Path '\(path.string)' exists and is not a file")
        }

        do {
            let stream = try file.open(mode: "a")
            unusedStreams.insert(stream)
            do {
                try stream.setBuffer(mode: .line)
            } catch {
                fatalError("Unable to use line buffered writes")
            }
            return .init(label: label, opened: stream, encoding: encoding)
        } catch {
            fatalError("Failed to open \(file) for appending")
        }
    }
}

public final class RotatingFileLogHandlerFactory<Handler: RotatingFileLogHandler>: _FileLogFactory {
    public var options: Handler.RotateOptions
    public var max: UInt?

    public convenience init(path: String,
                            encoding: String.Encoding = _FileLogFactory.defaultEncoding,
                            options: Handler.RotateOptions,
                            max: UInt? = nil) {
        if let file = FilePath(path) {
            self.init(file: file, encoding: encoding, options: options, max: max)
        } else if let dir = DirectoryPath(path) {
            self.init(directory: dir, encoding: encoding, options: options, max: max)
        } else {
            fatalError("Path '\(path)' must be either a file, directory, or nonexistent path (treated as a new file)")
        }
    }

    public convenience init(file: FilePath,
                            encoding: String.Encoding = _FileLogFactory.defaultEncoding,
                            options: Handler.RotateOptions,
                            max: UInt? = nil) {
        do {
            // Open the file for appending and create it if it doesn't exist
            try self.init(opened: file.open(mode: "a"), encoding: encoding, options: options, max: max)
        } catch {
            fatalError("Failed to open \(file) with error \(type(of: error)).\(error)")
        }
    }

    public init(directory: DirectoryPath,
                encoding: String.Encoding = _FileLogFactory.defaultEncoding,
                options: Handler.RotateOptions,
                max: UInt? = nil) {
        self.options = options
        self.max = max
        super.init(directory: directory, encoding: encoding)
    }

    private init(opened stream: FileStream,
                 encoding: String.Encoding = _FileLogFactory.defaultEncoding,
                 options: Handler.RotateOptions,
                 max: UInt? = nil) {
        self.options = options
        self.max = max
        super.init(opened: stream, encoding: encoding)
    }

    public func makeRotatingFileLogHandler(label: String) -> Handler {
        guard stream == nil else {
            return .init(label: label, opened: stream!, encoding: encoding, options: options, max: max)
        }

        let path = parent! + "\(label).log"
        guard let file = FilePath(path.absolute ?? path) else {
            fatalError("Path '\(path.string)' exists and is not a file")
        }

        do {
            let stream = try file.open(mode: "a")
            unusedStreams.insert(stream)
            do {
                try stream.setBuffer(mode: .line)
            } catch {
                fatalError("Unable to use line buffered writes")
            }
            return .init(label: label, opened: stream, encoding: encoding, options: options, max: max)
        } catch {
            fatalError("Failed to open \(file) for appending")
        }
    }
}
