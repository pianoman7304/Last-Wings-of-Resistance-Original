//
//  AppDelegate.swift
//  1942-ai
//
//  Created by Oliver Wyrsch on 7/2/25.
//


import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // The main window is created by the Main.storyboard.
        // We need to find that window and disable its close button.
        // We use DispatchQueue.main.async to ensure the window has been loaded.
        DispatchQueue.main.async {
            if let window = NSApplication.shared.mainWindow {
                if let closeButton = window.standardWindowButton(.closeButton) {
                    closeButton.isEnabled = false
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}
