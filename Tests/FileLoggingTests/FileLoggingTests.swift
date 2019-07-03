@testable import FileLogging
import XCTest

final class FileLoggingTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FileLogging().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
