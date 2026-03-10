//
//  _5PuzzleMetalTests.swift
//  15PuzzleMetalTests
//

import Testing
@testable import _5PuzzleMetal

@MainActor
struct _5PuzzleMetalTests {

    @Test func appDelegateExists() async throws {
        let _ = AppDelegate()
        // If it reaches here without crashing, instantiation succeeded.
    }

}
