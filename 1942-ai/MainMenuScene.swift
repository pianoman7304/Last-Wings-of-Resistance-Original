import SpriteKit
import AVFoundation
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

class MainMenuScene: SKScene {
    var buttonNodes: [SKLabelNode] = []
    var originalColors: [SKLabelNode: SKColor] = [:]
    
    #if os(macOS)
    var intelWindow: NSWindow?
    var controlsWindow: NSWindow?
    #endif
    
    var backgroundMusicPlayer: AVAudioPlayer?
    
    var menuSpriteNodes: [SKNode] = []
    var selectedMenuIndex: Int = 0

    override func didMove(to view: SKView) {
        
        //Add background image, always fill the scene
        let bg = SKSpriteNode(imageNamed: "start-page.png")
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.size = size // Always fill the scene
        bg.zPosition = -1
        bg.texture?.filteringMode = .nearest
        addChild(bg)
        backgroundColor = .black
        
        // Add game controller support for macOS and iOS and tvOS
        ControllerInputHandler.shared.registerMainMenuScene(self)

        // Use a base width (e.g., 1024) for scaling reference
        HelperFunctions.scaleFactor = size.width / HelperFunctions.preferredSceneSize.width  * 3.0 // Double the scale factor for larger images
        
        // Add game title at the top using writeTextWithSprites
        let titleNode = HelperFunctions.writeTextWithSprites("Last Wings of the Resistance", charSize: CGSize(width: 24, height: 24), spacing: 2.0)
        titleNode.position = CGPoint(x: 20 * HelperFunctions.scaleFactor , y: size.height - 40 * HelperFunctions.scaleFactor )
        titleNode.zPosition = 10
        addChild(titleNode)
        
        playBackgroundMusic()
        
        // create menu
        createMenu()
        selectedMenuIndex = 0 // Select the first menu item by default
        updateMenuSelection()
        
        // Add credits in very small font, lower right corner, half transparent
        let creditsText = "Credits:\nFamily Wyrsch Summer Project 2025\nIdea, Design & Coding: OW + 2 Bots\nMission Design, Enhancements & Testing: NW & UW"
        let creditsLabel = SKLabelNode(text: creditsText)
        creditsLabel.fontName = "AvenirNext-Regular"
        creditsLabel.fontSize = 4 * HelperFunctions.scaleFactor
        creditsLabel.fontColor = SKColor.white
        creditsLabel.alpha = 0.5
        creditsLabel.horizontalAlignmentMode = .right
        creditsLabel.verticalAlignmentMode = .bottom
        creditsLabel.numberOfLines = 2
        creditsLabel.preferredMaxLayoutWidth = size.width * 0.5
        creditsLabel.position = CGPoint(x: size.width - 10 * HelperFunctions.scaleFactor, y: 10 * HelperFunctions.scaleFactor)
        creditsLabel.zPosition = 100
        addChild(creditsLabel)
        
        // Count mission files in Resources/Missions
        let missionFiles = Bundle.main.paths(forResourcesOfType: "txt", inDirectory: nil)
            .filter { $0.contains("Mission ") }
        let missionNames = missionFiles.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        let missionCount = missionNames.count

        // Add mission count label, styled like credits, on the same line as the 4th line of credits
        let missionsLabel = SKLabelNode(text: String(format: "Missions loaded: %02d", missionCount))
        missionsLabel.fontName = "AvenirNext-Regular"
        missionsLabel.fontSize = 4 * HelperFunctions.scaleFactor
        missionsLabel.fontColor = SKColor.white
        missionsLabel.alpha = 0.5
        missionsLabel.horizontalAlignmentMode = .left
        missionsLabel.verticalAlignmentMode = .bottom
        // Place it below the credits label, adjust as needed for your font size/spacing
        missionsLabel.position = CGPoint(x: 20 * HelperFunctions.scaleFactor, y: 10 * HelperFunctions.scaleFactor + 10 * HelperFunctions.scaleFactor)
        missionsLabel.zPosition = 100
        addChild(missionsLabel)
        
        // Add controller connection status label below missionsLabel
        let controllerStatusText = ControllerInputHandler.isControllerAvailable() ? "Controller connected" : "No controller connected"
        let controllerStatusLabel = SKLabelNode(text: controllerStatusText)
        controllerStatusLabel.fontName = "AvenirNext-Regular"
        controllerStatusLabel.fontSize = 4 * HelperFunctions.scaleFactor
        controllerStatusLabel.fontColor = SKColor.white
        controllerStatusLabel.alpha = 0.5
        controllerStatusLabel.horizontalAlignmentMode = .left
        controllerStatusLabel.verticalAlignmentMode = .bottom
        controllerStatusLabel.position = CGPoint(x: missionsLabel.position.x, y: missionsLabel.position.y - 10 * HelperFunctions.scaleFactor)
        controllerStatusLabel.zPosition = 100
        addChild(controllerStatusLabel)
    }

    func createMenu() {
        // Remove old menu nodes if any
        for node in menuSpriteNodes { node.removeFromParent() }
        menuSpriteNodes.removeAll()
        // Button titles in order
        #if os(iOS)
        let buttonTitles = ["Take Off", "Intel", "Diary", "Flight Manual"]
        let buttonNames = ["newGame", "intel", "story", "controls"]
        #else
        let buttonTitles = ["Take Off", "Intel", "Diary", "Flight Manual", "Quit"]
        let buttonNames = ["newGame", "intel", "story", "controls", "quit"]
        #endif
        let buttonSpacing: CGFloat = 40 * HelperFunctions.scaleFactor  // vertical spacing between buttons
        let startY = size.height - 100 * HelperFunctions.scaleFactor  // starting Y position for the first button
        for (i, title) in buttonTitles.enumerated() {
            let spriteNode = HelperFunctions.writeTextWithSprites(title, charSize: CGSize(width: 19, height: 19), spacing: 1.6)
            spriteNode.position = CGPoint(x: 50, y: startY - CGFloat(i) * buttonSpacing) // Left aligned
            spriteNode.name = buttonNames[i]
            addChild(spriteNode)
            menuSpriteNodes.append(spriteNode)
        }
    }

    func updateMenuSelection() {
        for (i, node) in menuSpriteNodes.enumerated() {
            // Change color to red for selected, white for others
            for child in node.children {
                if let sprite = child as? SKSpriteNode {
                    if i == selectedMenuIndex {
                        sprite.color = .red
                        sprite.colorBlendFactor = 1.0
                    } else {
                        sprite.color = .white
                        sprite.colorBlendFactor = 1.0
                    }
                }
            }
        }
    }
    
    // game controller input handling
    
    func moveMenuSelection(up: Bool) {
        if up {
            selectedMenuIndex = (selectedMenuIndex - 1 + menuSpriteNodes.count) % menuSpriteNodes.count
            updateMenuSelection()
        } else {
            selectedMenuIndex = (selectedMenuIndex + 1) % menuSpriteNodes.count
            updateMenuSelection()
        }
    }
    
    // keys MacOS
    
    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: // Down arrow
            selectedMenuIndex = (selectedMenuIndex + 1) % menuSpriteNodes.count
            updateMenuSelection()
        case 126: // Up arrow
            selectedMenuIndex = (selectedMenuIndex - 1 + menuSpriteNodes.count) % menuSpriteNodes.count
            updateMenuSelection()
        case 49: // Space bar
            handleMenuSelection()
        case 36: // Return/Enter key
            handleMenuSelection()
        default:
            super.keyDown(with: event)
        }
    }
    #elseif os(iOS)
    
    // touches for iOS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for (i, node) in menuSpriteNodes.enumerated() {
            if node.contains(location) {
                selectedMenuIndex = i
                updateMenuSelection()
                handleMenuSelection()
                break
            }
        }
    }
    
    #endif

    func handleMenuSelection() {
        let selectedNode = menuSpriteNodes[selectedMenuIndex]
        switch selectedNode.name {
        case "newGame":
            if let view = self.view {
                stopBackgroundMusic()
                //let designSize = HelperFunctions.preferredSceneSize
                HelperFunctions.transitionToGameScene(from: view, missionNumber: 1, priorMissionsScore: 0)
            }
                 
        case "intel":
                if let view = self.view {
                    stopBackgroundMusic()
                    HelperFunctions.transitionToImageSequenceScene(
                        from: view,
                        imageNames: ["intel.png"]
                    )
                    //HelperFunctions.transitionToInfoImageScene(from: view, imageName: "intel.png", title: "Intel")
                }
            case "story":
                if let view = self.view {
                    stopBackgroundMusic()
                    HelperFunctions.transitionToImageSequenceScene(
                        from: view,
                        imageNames: ["story1of3E.png", "story2of3E.png", "story3of3E.png"]
                    )
                }
            case "controls":
                if let view = self.view {
                    stopBackgroundMusic()
                    
                    #if os(macOS)
                    HelperFunctions.transitionToImageSequenceScene(
                        from: view,
                        imageNames: ["controls-macos.png", "controls-game-controller.png"]
                    )
                    #endif
                    
                    #if os(iOS)
                    HelperFunctions.transitionToImageSequenceScene(
                        from: view,
                        imageNames: ["controls-touch-screen.png", "controls-game-controller.png"]
                    )
                    #endif
                    
                    #if os(tvOS)
                    HelperFunctions.transitionToImageSequenceScene(
                        from: view,
                        imageNames: ["controls-game-controller.png"]
                    )
                    #endif
                }
            case "highScores":
                if let view = self.view {
                    stopBackgroundMusic()
                    HelperFunctions.transitionToHighScoreScene(from: view)
                }
        case "quit":
            #if os(macOS)
            stopBackgroundMusic()
            NSApplication.shared.terminate(nil)
            #endif
        default:
            break
        }
    }
    
    
    
    
    func playBackgroundMusic() {
        if let url = Bundle.main.url(forResource: "loop-chill-drum", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.volume = 0.7
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print("Could not play background music: \(error)")
            }
        } else {
            print("SpaceGame.caf not found in bundle.")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
}
