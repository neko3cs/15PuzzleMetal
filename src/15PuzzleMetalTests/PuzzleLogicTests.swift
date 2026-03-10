//
//  PuzzleLogicTests.swift
//  15PuzzleMetalTests
//

import Testing
@testable import _5PuzzleMetal

@MainActor
struct PuzzleLogicTests {

    @Test func testInitialState() async throws {
        let logic = PuzzleLogic()
        // Initially it should be shuffled, but not solved
        // (well, it could be solved by chance but very unlikely)
        #expect(!logic.isSolved)
    }

    @Test func testSolvedState() async throws {
        let logic = PuzzleLogic()
        // Force a solved state
        logic.board = Array(1...15) + [0]
        #expect(logic.isSolved)
    }

    @Test func testMoveUp() async throws {
        let logic = PuzzleLogic()
        // Set state: 0 is at index 5 (row 1, col 1)
        logic.board = Array(1...16) // 16 is dummy
        logic.board[5] = 0
        logic.board[1] = 2 // some value
        
        let moved = logic.move(direction: .up)
        #expect(moved)
        #expect(logic.board[1] == 0) // Moved to row 0, col 1
        #expect(logic.board[5] != 0)
    }
    
    @Test func testMoveDown() async throws {
        let logic = PuzzleLogic()
        // Set state: 0 is at index 5 (row 1, col 1)
        logic.board = Array(1...16)
        logic.board[5] = 0
        
        let moved = logic.move(direction: .down)
        #expect(moved)
        #expect(logic.board[9] == 0) // Moved to row 2, col 1
    }
    
    @Test func testMoveLeft() async throws {
        let logic = PuzzleLogic()
        // Set state: 0 is at index 5 (row 1, col 1)
        logic.board = Array(1...16)
        logic.board[5] = 0
        
        let moved = logic.move(direction: .left)
        #expect(moved)
        #expect(logic.board[4] == 0) // Moved to row 1, col 0
    }
    
    @Test func testMoveRight() async throws {
        let logic = PuzzleLogic()
        // Set state: 0 is at index 5 (row 1, col 1)
        logic.board = Array(1...16)
        logic.board[5] = 0
        
        let moved = logic.move(direction: .right)
        #expect(moved)
        #expect(logic.board[6] == 0) // Moved to row 1, col 2
    }
    
    @Test func testBoundaryConditions() async throws {
        let logic = PuzzleLogic()
        
        // At top-left corner
        logic.board = Array(1...16)
        logic.board[0] = 0
        #expect(!logic.move(direction: .up))
        #expect(!logic.move(direction: .left))
        #expect(logic.move(direction: .down))
        
        // At bottom-right corner
        logic.board = Array(1...16)
        logic.board[15] = 0
        #expect(!logic.move(direction: .down))
        #expect(!logic.move(direction: .right))
        #expect(logic.move(direction: .up))
    }
}
