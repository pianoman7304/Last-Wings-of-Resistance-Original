//
//  ViewController.swift
//  1942-ai
//
//  Created by Oliver Wyrsch on 7/2/25.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            // Load the MainMenuScene instead of GameScene.sks
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if let window = self.skView.window, !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }
}
