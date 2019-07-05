import TrailBlazer

var openedStreams: Set<FileStream> = []

public class FileLogFactory {
    fileprivate let parent: DirectoryPath?
    /// An opened file that can be written to
    fileprivate let stream: FileStream?
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    public static var defaultEncoding: String.Encoding = .utf8

    public convenience init(path: String,
                            encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        if let file = FilePath(path) {
            self.init(file: file, encoding: encoding)
        } else if let dir = DirectoryPath(path) {
            self.init(directory: dir, encoding: encoding)
        } else {
            fatalError("Path '\(path)' must be either a file, directory, or nonexistent path (treated as a new file)")
        }
    }

    public convenience init(file: FilePath,
                            encoding: String.Encoding = FileLogFactory.defaultEncoding) {
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
                encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        parent = directory
        stream = nil
        self.encoding = encoding
    }

    public init(opened file: FileStream,
                encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        parent = nil
        stream = file
        self.encoding = encoding
    }
}

public final class FileLogHandlerFactory: FileLogFactory {
    public func makeFileLogHandler(label: String) -> FileLogHandler {
        if let stream = self.stream {
            return FileLogHandler(label: label, opened: stream, encoding: encoding)
        }

        let path = parent! + "\(label).log"
        guard let file = FilePath(path.absolute ?? path) else {
            fatalError("Path '\(path.string)' exists and is not a file")
        }

        if let stream = openedStreams.first(where: { $0.path == file }) {
            return FileLogHandler(label: label, opened: stream, encoding: encoding)
        }

        guard let stream = (try? file.open(mode: "a")) else {
            fatalError("")
        }

        openedStreams.insert(stream)

        return FileLogHandler(label: label, opened: stream, encoding: encoding)
    }
}

public final class RotatingLogHandlerFactory: FileLogFactory {
    public var options: RotateOptions

    public static var defaultRotateOptions: RotateOptions = [.date(.daily)]

    public convenience init(path: String,
                            encoding: String.Encoding = FileLogFactory.defaultEncoding,
                            options: RotateOptions = RotatingLogHandlerFactory.defaultRotateOptions) {
        if let file = FilePath(path) {
            self.init(file: file, encoding: encoding, options: options)
        } else if let dir = DirectoryPath(path) {
            self.init(directory: dir, encoding: encoding, options: options)
        } else {
            fatalError("Path '\(path)' must be either a file, directory, or nonexistent path (treated as a new file)")
        }
    }

    public convenience init(file: FilePath,
                            encoding: String.Encoding = FileLogFactory.defaultEncoding,
                            options: RotateOptions = RotatingLogHandlerFactory.defaultRotateOptions) {
        do {
            // Open the file for appending and create it if it doesn't exist
            try self.init(opened: file.open(mode: "a"), encoding: encoding, options: options)
        } catch {
            fatalError("Failed to open \(file) with error \(type(of: error)).\(error)")
        }
    }

    public init(directory: DirectoryPath,
                encoding: String.Encoding = FileLogFactory.defaultEncoding,
                options: RotateOptions = RotatingLogHandlerFactory.defaultRotateOptions) {
        self.options = options
        super.init(directory: directory, encoding: encoding)
    }

    public init(opened file: FileStream,
                encoding: String.Encoding = FileLogFactory.defaultEncoding,
                options: RotateOptions = RotatingLogHandlerFactory.defaultRotateOptions) {
        self.options = options
        super.init(opened: file, encoding: encoding)
    }

    public func makeRotatingFileLogHandler(label: String) -> RotatingFileLogHandler {
        if let stream = self.stream {
            return RotatingFileLogHandler(label: label, opened: stream, encoding: encoding, options: options)
        }

        let path = parent! + "\(label).log"
        guard let file = FilePath(path.absolute ?? path) else {
            fatalError("Path '\(path.string)' exists and is not a file")
        }

        if let stream = openedStreams.first(where: { $0.path == file }) {
            return RotatingFileLogHandler(label: label, opened: stream, encoding: encoding, options: options)
        }

        guard let stream = (try? file.open(mode: "a")) else {
            fatalError("")
        }

        openedStreams.insert(stream)

        return RotatingFileLogHandler(label: label, opened: stream, encoding: encoding, options: options)
    }
}
