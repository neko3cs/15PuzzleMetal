//
//  PuzzleLogic.swift
//  15PuzzleMetal
//

import Foundation

enum MoveDirection {
    case up, down, left, right
}

class PuzzleLogic {
    let size = 4
    var board: [Int] // 0 represents the empty space
    var isSolved: Bool {
        for i in 0..<15 {
            if board[i] != i + 1 {
                return false
            }
        }
        return board[15] == 0
    }
    
    init() {
        board = Array(1...15) + [0]
        shuffle()
    }
    
    func shuffle() {
        // Start from solved state
        board = Array(1...15) + [0]
        
        // Perform many random valid moves to ensure solvability
        var moves = 0
        while moves < 200 {
            let directions: [MoveDirection] = [.up, .down, .left, .right]
            if move(direction: directions.randomElement()!) {
                moves += 1
            }
        }
        
        // If it happens to be solved after shuffle, shuffle again
        if isSolved {
            shuffle()
        }
    }
    
    @discardableResult
    func move(direction: MoveDirection) -> Bool {
        guard let emptyIndex = board.firstIndex(of: 0) else { return false }
        let row = emptyIndex / size
        let col = emptyIndex % size
        
        var targetIndex: Int?
        
        switch direction {
        case .up: // Blank space moves UP
            if row > 0 {
                targetIndex = emptyIndex - size
            }
        case .down: // Blank space moves DOWN
            if row < size - 1 {
                targetIndex = emptyIndex + size
            }
        case .left: // Blank space moves LEFT
            if col > 0 {
                targetIndex = emptyIndex - 1
            }
        case .right: // Blank space moves RIGHT
            if col < size - 1 {
                targetIndex = emptyIndex + 1
            }
        }
        
        if let target = targetIndex {
            board.swapAt(emptyIndex, target)
            return true
        }
        
        return false
    }
    
    func reset() {
        shuffle()
    }
}
