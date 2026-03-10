//
//  GameViewController.swift
//  15PuzzleMetal
//

import Cocoa
import MetalKit

class GameViewController: NSViewController {

    var renderer: Renderer!
    var puzzleLogic: PuzzleLogic!
    var winLabel: NSTextField!

    private var appearanceObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            return
        }

        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            return
        }

        renderer = newRenderer
        puzzleLogic = PuzzleLogic()
        
        // Pass initial model state to the view
        renderer.board = puzzleLogic.board
        renderer.boardSize = puzzleLogic.size
        
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        
        setupWinLabel()
        
        // Listen for appearance changes using modern KVO
        appearanceObserver = view.observe(\.effectiveAppearance, options: [.new]) { [weak self] view, _ in
            let capturedSelf = self
            Task { @MainActor in
                guard let self = capturedSelf, let mtkView = view as? MTKView else { return }
                let isDarkMode = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                self.renderer.updateBackgroundColor(view: mtkView, isDarkMode: isDarkMode)
                
                if let label = self.winLabel {
                    label.textColor = isDarkMode ? .systemYellow : .systemOrange
                }
            }
        }
    }
    
    deinit {
        appearanceObserver?.invalidate()
    }
    
    func setupWinLabel() {
        winLabel = NSTextField(labelWithString: "You did it!")
        winLabel.font = NSFont.boldSystemFont(ofSize: 48)
        
        let isDarkMode = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        winLabel.textColor = isDarkMode ? .systemYellow : .systemOrange
        winLabel.alignment = .center
        winLabel.isHidden = true
        
        view.addSubview(winLabel)
        winLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            winLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            winLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func keyDown(with event: NSEvent) {
        if let chars = event.charactersIgnoringModifiers {
            if chars == "r" && event.modifierFlags.contains(.command) {
                resetGame()
                return
            }
        }

        if puzzleLogic.isSolved { return }
        
        var moved = false
        if let chars = event.charactersIgnoringModifiers {
            switch chars {
            case "k": moved = puzzleLogic.move(direction: .up)
            case "j": moved = puzzleLogic.move(direction: .down)
            case "h": moved = puzzleLogic.move(direction: .left)
            case "l": moved = puzzleLogic.move(direction: .right)
            default: break
            }
        }
        
        if !moved {
            switch event.keyCode {
            case 126: moved = puzzleLogic.move(direction: .up)    // Up
            case 125: moved = puzzleLogic.move(direction: .down)  // Down
            case 123: moved = puzzleLogic.move(direction: .left)  // Left
            case 124: moved = puzzleLogic.move(direction: .right) // Right
            default: break
            }
        }
        
        if moved {
            // Update the view with new model state
            renderer.board = puzzleLogic.board
            
            if puzzleLogic.isSolved {
                winLabel.isHidden = false
            }
        }
    }
    
    @objc func resetGame() {
        puzzleLogic.reset()
        renderer.board = puzzleLogic.board
        winLabel.isHidden = true
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }
}
