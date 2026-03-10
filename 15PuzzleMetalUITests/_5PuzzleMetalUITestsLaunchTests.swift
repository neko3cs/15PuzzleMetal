//
//  _5PuzzleMetalUITestsLaunchTests.swift
//  15PuzzleMetalUITests
//

import XCTest

final class _5PuzzleMetalUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the main window title
        XCTAssertTrue(app.windows["15PuzzleMetal"].exists)

        // Capture a screenshot of the initial state
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Initial Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
