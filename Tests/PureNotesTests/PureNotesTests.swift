import XCTest
import OSLog
import Foundation
@testable import PureNotes

let logger: Logger = Logger(subsystem: "PureNotes", category: "Tests")

@available(macOS 13, *)
final class PureNotesTests: XCTestCase {
    func testPureNotes() throws {
        logger.log("running testPureNotes")
        XCTAssertEqual(1 + 2, 3, "basic test")
        
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("PureNotes", testData.testModuleName)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}