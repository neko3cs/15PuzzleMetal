//
//  AppDelegate.swift
//  15PuzzleMetal
//
//  Created by neko3cs on 2026/03/10.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainMenu = NSApp.mainMenu!
        
        let gameMenuItem = NSMenuItem(title: "Game", action: nil, keyEquivalent: "")
        let gameMenu = NSMenu(title: "Game")
        
        let resetItem = NSMenuItem(title: "Reset", action: #selector(GameViewController.resetGame), keyEquivalent: "r")
        resetItem.keyEquivalentModifierMask = .command
        
        gameMenu.addItem(resetItem)
        gameMenuItem.submenu = gameMenu
        
        mainMenu.insertItem(gameMenuItem, at: 1) // After the app menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
