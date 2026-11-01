//
//  ViewController.swift
//  1942-ai
//
//  Created by Oliver Wyrsch on 7/2/25.
//

#if os(macOS)

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {
    
    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // No window mode or size logic here; handled in viewDidAppear
        if let view = self.skView {
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFit //.aspectFill
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            //view.showsFPS = true
            //view.showsNodeCount = true
            
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        //
        if let window = self.skView.window {
            // Disable the close button
            window.styleMask.remove(.closable)
            window.standardWindowButton(.closeButton)?.isEnabled = false
            
            let maxWidth: CGFloat = 1470
            let maxHeight: CGFloat = 956
            let viewWidth = window.frame.width
            let viewHeight = window.frame.height
            let maxAspectRatio = maxWidth / maxHeight
            let currentAspectRatio = viewWidth / viewHeight
            
            if currentAspectRatio <= maxAspectRatio {
                // If not in fullscreen, toggle to fullscreen
                if !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
            // If too wide, stay in windowed mode and set size
            else {
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
                window.setContentSize(NSSize(width: maxWidth, height: maxHeight))
                window.center()
            }
        }
    }
}
#endif
