//
//  AppDelegate.swift
//  1942-ai
//
//  Created by Oliver Wyrsch on 7/2/25.
//


import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let window = NSApplication.shared.windows.first {
            window.title = "Last Wings of the Resistance"
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}
