# Swift Log File

A Swift logging backend that writes logs to files using the C [`fopen`](https://linux.die.net/man/3/fopen)/[`fwrite`](https://linux.die.net/man/3/fwrite) APIs.

It is an implementation of a [`LogHandler`](https://github.com/apple/swift-log#on-the-implementation-of-a-logging-backend-a-loghandler) as defined by the [Swift Server Working Group logging API](https://github.com/apple/swift-log).

## Installation (SPM)

Add the following dependency in your Package.swift
```swift
.package(url: "https://github.com/Ponyboy47/swift-log-file.git", .branch("master"))
```

## Usage

### Share a log file across loggers

During application startup:
```swift
import Logging
import FileLogging

// Create a factory which will point any newly created logs to the same file
let fileFactory = FileLogHandlerFactory(path: "/path/to/file.log")

// Initialize the file log handler
LoggingSystem.bootstrap(fileFactory.makeFileLogHandler)
```

Elsewhere:
```swift
// Create a logger
let logger = Logger(label: "MyApp")

// Write a log message
logger.info("Hello world!")
```

### Create a new log file for each logger

During application startup:
```swift
import Logging
import FileLogging

// Create a factory with just a directory where logs will be created
let fileFactory = FileLogHandlerFactory(path: "/path/to/logs/directory/")

// Initialize the file log handler
LoggingSystem.bootstrap(fileFactory.makeFileLogHandler)
```

Elsewhere:
```swift
// Creates a new log file at /path/to/logs/directory/MyApp.log
let logger = Logger(label: "MyApp")

logger.info("Hello world!")
```

## Rotating Handlers

This implementation includes both a date-based and size-based rotating mechanism for logs. The bootstrapping is a bit verbose, but it makes creating the loggers just as easy as what you see anywhere else.

#### Path
The `path` parameter for the `RotatingFileLogHandlerFactory` behaves exactly the same as the `path` parameter in the `FileLogHandlerFactory`. Specifying a file or uncreated path will be used as a `FilePath` while a directory will be used as a parent location for files based on the label during `Logger` creation.

#### Max
The `max` parameter defaults to `nil`. Passing a max of `nil` means old logs will never be deleted. It is good practice to include a maximum if you're expecting lots of logs or you can set up some other tool to clean up/offload extra files.

### Date Rotating Handlers

```swift
import Logging
import FileLogging

// Create a factory that will rotate logs at midnight every day and deletes any
// logs from more than 7 days ago
let dateRotatingFactory = RotatingFileLogHandlerFactory<DateRotatingFileLogHandler>(path: "/path/to/file.log", options: .daily, max: 7)

LoggingSystem.bootstrap(dateRotatingFactory.makeRotatingFileLogHandler)
```

Elsewhere
```swift
let logger = Logger(label: "MyApp")

logger.info("Hello world!")
```

### Size Rotating Handlers

```swift
import Logging
import FileLogging

// Create a factory that will rotate logs as soon as the size would exceed 100
// megabytes and only permits up to 5 rotations before deleting old log files
let sizeRotatingFactory = RotatingFileLogHandlerFactory<SizeRotatingFileLogHandler>(path: "/path/to/file.log", options: 100.megabytes, max: 5)

LoggingSystem.bootstrap(sizeRotatingFactory.makeRotatingFileLogHandler)
```

Elsewhere
```swift
let logger = Logger(label: "MyApp")

logger.info("Hello world!")
```

## Todo

- [ ] Track when we were passed FileStreams directly so we know not to close them explicitly
- [ ] Don't use so many fatalErrors
- [ ] Performance tests
- [ ] Find some shorter names for things (RotatingFileLogHandlerFactory? And it requires a generic type?)
- [ ] Allow customizing the datetime format printed in the logs

## License
MIT (c) 2019 Jacob Williams
