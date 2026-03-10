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
    func testGameWinWorkflow() throws {
        let app = XCUIApplication()
        app.launch()

        let window = app.windows["15PuzzleMetal"]
        XCTAssertTrue(window.exists)
        
        // 1. Force near-solved state using debug key (Option + W)
        window.typeKey("w", modifierFlags: .option)
        
        // 2. The near-solved state has 0 at index 14 and 15 at index 15.
        // To win, we need to move 15 to the LEFT (into index 14).
        // In our logic, 'h' moves the blank space LEFT, which moves the tile to its RIGHT into the blank.
        // Wait, if blank is at 14 and 15 is at 15, we need to move the blank space RIGHT ('l' or Right Arrow).
        window.typeKey("l", modifierFlags: [])
        
        // 3. Verify the "You did it!" label appears
        let winLabel = app.staticTexts["WinLabel"]
        XCTAssertTrue(winLabel.waitForExistence(timeout: 2.0))
        XCTAssertTrue(winLabel.isHittable)
        
        // 4. Verify that we can't move anymore (app should still be responsive but logic is locked)
        window.typeKey(XCUIKeyboardKey.upArrow, modifierFlags: [])
        XCTAssertTrue(winLabel.exists) // Label should still be there
        
        // 5. Reset the game and verify the label disappears
        window.typeKey("r", modifierFlags: .command)
        XCTAssertFalse(winLabel.exists)
    }

    @MainActor
    func testMenuInteractions() throws {
        let app = XCUIApplication()
        app.launch()
        
        let menuBarsQuery = app.menuBars
        let gameMenu = menuBarsQuery.menuBarItems["Game"]
        XCTAssertTrue(gameMenu.exists)
        
        gameMenu.click()
        let resetMenuItem = menuBarsQuery.menus.menuItems["Reset"]
        XCTAssertTrue(resetMenuItem.exists)
        resetMenuItem.click()
    }
}
