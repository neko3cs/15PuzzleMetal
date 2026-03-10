//
//  GameViewController.swift
//  15PuzzleMetal
//

import Cocoa
import MetalKit

class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!
    var winLabel: NSTextField!

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
        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = renderer
        
        setupWinLabel()
        
        // Listen for appearance changes
        self.view.addObserver(self, forKeyPath: "effectiveAppearance", options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {
            let isDarkMode = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            renderer.updateBackgroundColor(isDarkMode: isDarkMode)
            
            // Also update winLabel color
            winLabel.textColor = isDarkMode ? .systemYellow : .systemOrange
        }
    }
    
    deinit {
        self.view.removeObserver(self, forKeyPath: "effectiveAppearance")
    }
    
    func setupWinLabel() {
        winLabel = NSTextField(labelWithString: "You did it!")
        winLabel.font = NSFont.boldSystemFont(ofSize: 48)
        winLabel.textColor = .systemYellow
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

        if renderer.puzzleLogic.isSolved { return }
        
        var moved = false
        if let chars = event.charactersIgnoringModifiers {
            switch chars {
            case "k": moved = renderer.puzzleLogic.move(direction: .up)
            case "j": moved = renderer.puzzleLogic.move(direction: .down)
            case "h": moved = renderer.puzzleLogic.move(direction: .left)
            case "l": moved = renderer.puzzleLogic.move(direction: .right)
            default: break
            }
        }
        
        if !moved {
            switch event.keyCode {
            case 126: moved = renderer.puzzleLogic.move(direction: .up)    // Up
            case 125: moved = renderer.puzzleLogic.move(direction: .down)  // Down
            case 123: moved = renderer.puzzleLogic.move(direction: .left)  // Left
            case 124: moved = renderer.puzzleLogic.move(direction: .right) // Right
            default: break
            }
        }
        
        if moved {
            if renderer.puzzleLogic.isSolved {
                winLabel.isHidden = false
            }
        }
    }
    
    @objc func resetGame() {
        renderer.puzzleLogic.reset()
        winLabel.isHidden = true
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }
}
