@testable import FileLogging
import Foundation
import Logging
import Pathman
import XCTest

final class FileLoggingTests: XCTestCase {
    func testHammer() {
        var logFile = FilePath("/tmp/test.log")!

        let factory = FileLogHandlerFactory(file: logFile)
        LoggingSystem.bootstrap(factory.makeFileLogHandler)
        let logger = Logger(label: "com.ponyboy47.test")

        let end = Date() + 30
        let startSize = logFile.size
        while Date() < end {
            logger.info("Test message")
        }

        XCTAssertTrue(logFile.size > startSize)
        try? logFile.delete()
    }

    func testHammerRotating() {
        let logFile = FilePath("/tmp/test.log")!

        let factory = RotatingFileLogHandlerFactory<DateRotatingFileLogHandler>(file: logFile, options: 9.seconds)
        LoggingSystem.bootstrap(factory.makeRotatingFileLogHandler)
        let logger = Logger(label: "com.ponyboy47.test")

        let end = Date() + 30
        while Date() < end {
            logger.info("Test message")
        }
        (try? glob(pattern: "/tmp/test*.log"))?.matches.files.forEach { log in
            var log = log
            try? log.delete()
        }
    }

    static var allTests = [
        ("testHammer", testHammer),
        ("testHammerRotating", testHammerRotating)
    ]
}
