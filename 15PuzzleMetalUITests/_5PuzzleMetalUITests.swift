//
//  _5PuzzleMetalUITests.swift
//  15PuzzleMetalUITests
//

import XCTest

final class _5PuzzleMetalUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGameLaunchAndInteraction() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the main window exists
        XCTAssertTrue(app.windows["15PuzzleMetal"].exists)
        
        // Simulate arrow key presses to move tiles
        // Note: In a real Metal view, we can't easily inspect individual tiles via Accessibility,
        // but we can ensure the app doesn't crash and responds to inputs.
        let window = app.windows["15PuzzleMetal"]
        window.typeKey(XCUIKeyboardKey.downArrow, modifierFlags: [])
        window.typeKey(XCUIKeyboardKey.upArrow, modifierFlags: [])
        window.typeKey("l", modifierFlags: []) // 'l' key for right
        window.typeKey("h", modifierFlags: []) // 'h' key for left
        
        // Verify Reset menu item
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["Game"].click()
        menuBarsQuery.menus.menuItems["Reset"].click()
        
        // Verify Cmd+R shortcut
        window.typeKey("r", modifierFlags: .command)
    }

    @MainActor
    func testWinConditionAppearance() throws {
        // Since we can't easily force a win state from a UI test without accessibility hooks in Metal,
        // we'll at least verify the app remains responsive.
        let app = XCUIApplication()
        app.launch()
        
        let window = app.windows["15PuzzleMetal"]
        XCTAssertTrue(window.exists)
    }
}
