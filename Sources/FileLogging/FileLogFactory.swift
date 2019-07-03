import TrailBlazer

private var openedStreams: Set<FileStream> = []

public class FileLogFactory {
    fileprivate let parent: DirectoryPath?
    /// An opened file that can be written to
    fileprivate let stream: FileStream?
    /// The encoding to use when converting a String log message to bytes which can be written to the file
    public var encoding: String.Encoding

    public static var defaultEncoding: String.Encoding = .utf8

    /**
     Initialize a
     **/
    public convenience init(path: String, encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        // Make sure the path is to a valid file
        if let file = FilePath(path) {
            self.init(file: file, encoding: encoding)
        } else if let dir = DirectoryPath(path) {
            self.init(directory: dir, encoding: encoding)
        } else {
            fatalError("Path '\(path)' must be either a file, directory, or nonexistent path (treated as a new file)")
        }
    }

    public convenience init(file: FilePath, encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        do {
            // Open the file for appending and create it if it doesn't exist
            try self.init(opened: file.open(mode: "a"), encoding: encoding)
        } catch {
            fatalError("Failed to open \(file) with error \(type(of: error)).\(error)")
        }
    }

    public init(directory: DirectoryPath, encoding: String.Encoding = FileLogFactory.defaultEncoding) {
        parent = directory
        stream = nil
        self.encoding = encoding
    }

    public init(opened file: FileStream, encoding: String.Encoding = FileLogFactory.defaultEncoding) {
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
    public var rotateOptions: RotateOptions = [.date(.daily)]
}
