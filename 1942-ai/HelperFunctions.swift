import SpriteKit
import AVFoundation

class HelperFunctions {
    static var scaleFactor: CGFloat = 1.0 // need to get this from game scene or set it globally
    static let fontImageName = "Font Pixels Extended.png"
    static let charsPerRow = 10
    static let charRows = 4
    static let charMap: [[Character]] = [
        Array("ABCDEFGHI!"),
        Array("JKLMNOPQR."),
        Array("STUVWXYZ- "),
        Array("0123456789")
    ]
    static var charTextures: [Character: SKTexture] = [:]
    static var isLoaded = false
   
    
    // Adjusts the window size for wide screens, default full screen, if too wide window mode
    static let preferredSceneSize = CGSize(width: 1470, height: 956) // for mac airbook, otherwise traditional: CGSize(width: 1024, height: 640)
    
    // Transition functions to switch scenes
    
    static func transitionToMainMenuScene(from view: SKView) {
        let menuScene = MainMenuScene(size: HelperFunctions.preferredSceneSize)
        menuScene.scaleMode = .aspectFit
        view.presentScene(menuScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    static func transitionToMissionEndScene(from view: SKView, currentMissionNumber: Int, killsPerEnemyType: [String: Int], score: Int, priorMissionsScore: Int, maxMissionNumber: Int, playerDied: Bool) {
        let endScene = MissionEndScene(size: HelperFunctions.preferredSceneSize)
        endScene.currentMissionNumber = currentMissionNumber
        endScene.killsPerEnemyType = killsPerEnemyType
        endScene.missionScore = score
        endScene.totalScoreBefore = priorMissionsScore
        endScene.totalScoreAfter = priorMissionsScore + score
        endScene.isLastMission = (currentMissionNumber >= maxMissionNumber)
        endScene.playerDied = playerDied
        endScene.scaleMode = .aspectFit
        view.presentScene(endScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    static func transitionToGameScene(from view: SKView, missionNumber: Int, priorMissionsScore: Int) {
        let gameScene = GameScene(size: HelperFunctions.preferredSceneSize)
        gameScene.currentMissionNumber = missionNumber
        gameScene.priorMissionsScore = priorMissionsScore
        gameScene.scaleMode = .aspectFit
        view.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    static func transitionToHighScoreScene(from view: SKView) {
        let highScoreScene = HighScoreScene(size: HelperFunctions.preferredSceneSize)
        highScoreScene.scaleMode = .aspectFit
        view.presentScene(highScoreScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    static func transitionToImageSequenceScene(from view: SKView, imageNames: [String]) {
        let imageSequenceScene = ImageSequenceScene(size: HelperFunctions.preferredSceneSize, imageNames: imageNames)
        imageSequenceScene.scaleMode = .aspectFit
        view.presentScene(imageSequenceScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    // Call this once before using writeTextWithSprites
    static func loadFontSprites() {
        guard !isLoaded else { return }

        guard let fontTexture = SKTexture(imageNamed: fontImageName) as SKTexture?, fontTexture.size().width > 0, fontTexture.size().height > 0 else {
            print("[HelperFunctions] ERROR: Font Pixels.png could not be loaded or has zero size. Check if the file exists in the bundle and is named correctly.")
            return
        }
       
        let textureSize = fontTexture.size()
        let charWidth = textureSize.width / CGFloat(charsPerRow)
        let charHeight = textureSize.height / CGFloat(charRows)
        for row in 0..<charRows {
            for col in 0..<charsPerRow {
                let char = charMap[row][col]
                let rect = CGRect(
                    x: CGFloat(col) * charWidth / textureSize.width,
                    y: CGFloat(charRows - 1 - row) * charHeight / textureSize.height,
                    width: charWidth / textureSize.width,
                    height: charHeight / textureSize.height
                )
                let texture = SKTexture(rect: rect, in: fontTexture)
                charTextures[char] = texture
            }
        }
        isLoaded = true
    }

    // Writes text as a row of SKSpriteNodes using the font sprites
    // Returns a parent SKNode containing the character sprites
    
    static func writeTextWithSprites(_ text: String, charSize: CGSize = CGSize(width: 24, height: 24), spacing: CGFloat = 2) -> SKNode {
        let fontScaleFactor = 0.5 // Adjust this to scale the font size
        loadFontSprites()
        let node = SKNode()
        let upperText = text.uppercased()
        let scaledCharSize = CGSize(width: charSize.width * HelperFunctions.scaleFactor * fontScaleFactor, height: charSize.height * HelperFunctions.scaleFactor * fontScaleFactor)
        let scaledSpacing = spacing * HelperFunctions.scaleFactor * fontScaleFactor
        var x: CGFloat = 0
        for c in upperText {
            let char: Character
            if charTextures[c] != nil {
                char = c
            } else if charTextures[" "] != nil {
                char = " "
            } else {
                char = " "
            }
            let sprite = SKSpriteNode(texture: charTextures[char])
            sprite.size = scaledCharSize
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: x, y: 0)
            node.addChild(sprite)
            x += scaledCharSize.width + scaledSpacing
        }
        return node
    }

    // --- Custom Dialog Creation ---
    static func createCustomDialog(question: String, options: [String]) -> SKNode {
        let container = SKNode()
        container.zPosition = 3000

        // Create question node
        let questionNode = writeTextWithSprites(question, charSize: CGSize(width: 28, height: 28), spacing: 2)
        let questionWidth = questionNode.calculateAccumulatedFrame().width
        questionNode.position = CGPoint(x: -questionWidth / 2, y: 20) // Centered, upper line
        container.addChild(questionNode)

        // Create options node
        let optionsString = options.joined(separator: " - ")
        let optionsNode = writeTextWithSprites(optionsString, charSize: CGSize(width: 28, height: 28), spacing: 2)
        optionsNode.name = "optionsNode" // Name it for easy access
        let optionsWidth = optionsNode.calculateAccumulatedFrame().width
        optionsNode.position = CGPoint(x: -optionsWidth / 2, y: -30) // Centered, lower line
        container.addChild(optionsNode)
        
        return container
    }
    
    static func loadExplosionFrames() -> [SKTexture] {
        let imageName = "explosion.png"
        guard let explosionTexture = SKTexture(imageNamed: imageName) as SKTexture?,
              explosionTexture.size().width > 0, explosionTexture.size().height > 0 else {
            print("[HelperFunctions] ERROR: explosion.jpg could not be loaded or has zero size. Check if the file exists in the bundle and is named correctly.")
            return []
        }
        var frames: [SKTexture] = []
        let columns = 4
        let rows = 4
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)
        for row in 0..<rows {
            for col in 0..<columns {
                let rect = CGRect(x: CGFloat(col) * frameWidth,
                                  y: 1.0 - frameHeight - CGFloat(row) * frameHeight,
                                  width: frameWidth,
                                  height: frameHeight)
                let frame = SKTexture(rect: rect, in: explosionTexture)
                frames.append(frame)
            }
        }
        return frames
    }
    
    // Helper function to update the text of a sprite label
    static func setTextForSpriteLabel(_ label: SKNode, text: String, charSize: CGSize = CGSize(width: 24, height: 24), spacing: CGFloat = 2) {
        label.removeAllChildren()
        let newLabel = writeTextWithSprites(text, charSize: charSize, spacing: spacing)
        for child in newLabel.children {
            label.addChild(child.copy() as! SKNode)
        }
    }
}


extension GameScene {
    
    // Add a helper function for bold fonts
    func boldFont(size: CGFloat) -> String {
        return "Courier-Bold"
    }
    
    //background music handling
    
    func playBackgroundMusic() {
        if let url = Bundle.main.url(forResource: "SpaceGame", withExtension: "caf") {
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
    
    // Show a custom dialog with options
    
    func showCustomDialog(node: SKNode, options: [String]) {
        isGamePaused = true
        exitPopupSelection = 0
        
        // Store options in userData for the keyDown handler
        node.userData = ["options": options]
        
        // Place the popup in the center of the screen
        node.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(node)
        /*
        if let window = self.view?.window {
            window.makeFirstResponder(self)
        }
        */
        customExitPopupNode = node
        
        if options.count == 1 {
            // Single option dialog, like "OK". Color it red immediately.
            if let optionsNode = node.childNode(withName: "optionsNode") {
                for case let sprite as SKSpriteNode in optionsNode.children {
                    sprite.color = .red
                    sprite.colorBlendFactor = 1.0
                }
            }
        } else {
            // Multi-option dialog, like "Stay / Leave". Use selection logic.
            updateCustomExitPopupSelection()
        }
    }
    
    // --- Custom Exit Popup ---
    /*
    func updateCustomExitPopupSelection() {
        guard let container = customExitPopupNode,
              let optionsNode = container.childNode(withName: "optionsNode") else { return }
        
        // The text is: "Stay - Leave"
        let optionsText = "Stay - Leave"
        let stayText = "Stay"
        let leaveText = "Leave"
        
        guard let stayRange = optionsText.range(of: stayText),
              let leaveRange = optionsText.range(of: leaveText) else { return }
        
        let stayStartIndex = optionsText.distance(from: optionsText.startIndex, to: stayRange.lowerBound)
        let leaveStartIndex = optionsText.distance(from: optionsText.startIndex, to: leaveRange.lowerBound)
        
        let sprites = optionsNode.children.compactMap { $0 as? SKSpriteNode }
        for (i, sprite) in sprites.enumerated() {
            // Reset color to white first
            sprite.color = .white
            sprite.colorBlendFactor = 1.0
            
            if exitPopupSelection == 0 { // Stay selected

                if i >= stayStartIndex && i < stayStartIndex + stayText.count {
                    sprite.color = .red
                }
            } else { // Leave selected

                if i >= leaveStartIndex && i < leaveStartIndex + leaveText.count {
                    sprite.color = .red
                }
            }
        }
    }
     */
    
    func updateCustomExitPopupSelection() {
        guard let container = customExitPopupNode,
              let optionsNode = container.childNode(withName: "optionsNode"),
              let options = container.userData?["options"] as? [String] else { return }

        // Build the options string and get the start index for each option
        let optionsString = options.joined(separator: " - ")
        var optionRanges: [Range<Int>] = []
        var currentIndex = 0
        for option in options {
            let range = currentIndex..<(currentIndex + option.count)
            optionRanges.append(range)
            currentIndex += option.count + 3 // 3 for " - "
        }
        if !optionRanges.isEmpty { optionRanges[optionRanges.count - 1] = (optionRanges.last!.lowerBound)..<optionsString.count }

        let sprites = optionsNode.children.compactMap { $0 as? SKSpriteNode }
        for (i, sprite) in sprites.enumerated() {
            sprite.color = .white
            sprite.colorBlendFactor = 1.0
            if exitPopupSelection < optionRanges.count {
                let range = optionRanges[exitPopupSelection]
                if i >= range.lowerBound && i < range.upperBound {
                    sprite.color = .red
                }
            }
        }
    }
    
    // Show a dialog for mission end with options
    // --- Custom Exit Popup ---
    func showCustomExitPopup() {
        guard customExitPopupNode == nil else { return }
        
        // Use the helper function to create the dialog
        let dialogNode = HelperFunctions.createCustomDialog(
            question: "Leave the mission?",
            options: ["Stay", "Leave"]
        )
        dialogNode.name = "customExitPopupNode"
        
        // Show the dialog using the generic handler
        showCustomDialog(node: dialogNode, options: ["Stay", "Leave"])
        /*
        if let window = self.view?.window {
            window.makeFirstResponder(self)
        }*/
        
        //print("customExitPopupNode is now set:", customExitPopupNode)
    }
    
    // Navigates to the previous dialog option (for controller left)
    func selectPreviousDialogOption() {
        guard let popup = customExitPopupNode,
              let options = popup.userData?["options"] as? [String], options.count > 1 else { return }
        exitPopupSelection = max(0, exitPopupSelection - 1)
        updateCustomExitPopupSelection()
    }

    // Navigates to the next dialog option (for controller right)
    func selectNextDialogOption() {
        guard let popup = customExitPopupNode,
              let options = popup.userData?["options"] as? [String], options.count > 1 else { return }
        exitPopupSelection = min(options.count - 1, exitPopupSelection + 1)
        updateCustomExitPopupSelection()
    }

    // Confirms the current dialog selection (for controller X/Cross)
    func confirmDialogSelection() {
        guard let popup = customExitPopupNode,
              let options = popup.userData?["options"] as? [String] else { return }
        if options.count == 1 {
            // Single-option dialog (e.g. OK, error)
            removeCustomExitPopup()
        } else if options.count == 2 {
            if exitPopupSelection == 0 {
                // "Stay" selected
                removeCustomExitPopup()
            } else {
                // "Leave" selected
                if let view = self.view {
                    HelperFunctions.transitionToMainMenuScene(from: view)
                }
            }
        }
    }
    
    
    func removeCustomExitPopup() {
        customExitPopupNode?.removeFromParent()
        customExitPopupNode = nil
        isGamePaused = false
    }
    
    // Show a red error dialog if the mission file is not found or is the wrong length
    func showMissionFileErrorDialog() {
        let dialogNode = HelperFunctions.createCustomDialog(question: "Mission file not loading!", options: ["OK"])
        dialogNode.name = "missionFileErrorPopup"
        showCustomDialog(node: dialogNode, options: ["OK"])
    }

    // Show a dialog for game over with options
    func showGameOverDialog() {
        let dialogNode = HelperFunctions.createCustomDialog(question: "Game Over! You died!", options: ["OK"])
        dialogNode.name = "gameOverPopup"
        showCustomDialog(node: dialogNode, options: ["OK"])
    }
    
    // Show a dialog for mission completed with options
    func showMissionCompletedDialog() {
        let dialogNode = HelperFunctions.createCustomDialog(question: "Mission completed!", options: ["OK"])
        dialogNode.name = "missionCompletedPopup"
        showCustomDialog(node: dialogNode, options: ["OK"])
    }
    
    
    // Runs the explosion animation at a given position in the scene
    func runExplosionAnimation(at position: CGPoint, in scene: SKScene, size: CGSize = CGSize(width: 64, height: 64), zPosition: CGFloat? = nil) {
        let frames = HelperFunctions.loadExplosionFrames()
        guard !frames.isEmpty else { return }
        let explosionNode = SKSpriteNode(texture: frames.first)
        explosionNode.position = position
        explosionNode.size = size
        if let z = zPosition {
            explosionNode.zPosition = z
        } else {
            explosionNode.zPosition = 1000
        }
        scene.addChild(explosionNode)
        let animation = SKAction.animate(with: frames, timePerFrame: 0.04)
        let remove = SKAction.removeFromParent()
        explosionNode.run(SKAction.sequence([animation, remove]))
    }
    
    func setupScoreLabel() {
        // Remove old score label if any
        scoreLabel?.removeFromParent()
        self.childNode(withName: "spriteScoreLabel")?.removeFromParent()
        // Use writeTextWithSprites to create the score display
        let scoreString = String(format: "%06d", score)
        let spriteScoreNode = HelperFunctions.writeTextWithSprites(scoreString, charSize: CGSize(width: 28, height: 28), spacing: 2)
        // Place 50 px from right and 140 px from top (moved 40px down)
        let x = size.width - 50 - spriteScoreNode.calculateAccumulatedFrame().width
        let y = size.height - 120
        spriteScoreNode.position = CGPoint(x: x, y: y)
        spriteScoreNode.zPosition = 1000
        spriteScoreNode.name = "spriteScoreLabel"
        addChild(spriteScoreNode)
        // Store reference for updating
        scoreLabel = SKLabelNode() // dummy, not used for display
    }
    
    func updateScoreLabel() {
        // Remove old sprite score node
        self.childNode(withName: "spriteScoreLabel")?.removeFromParent()
        // Use writeTextWithSprites to create the updated score display
        let scoreString = String(format: "%06d", score)
        let spriteScoreNode = HelperFunctions.writeTextWithSprites(scoreString, charSize: CGSize(width: 28, height: 28), spacing: 2)
        let x = size.width - 50 - spriteScoreNode.calculateAccumulatedFrame().width
        let y = size.height - 120
        spriteScoreNode.position = CGPoint(x: x, y: y)
        spriteScoreNode.zPosition = 1000
        spriteScoreNode.name = "spriteScoreLabel"
        addChild(spriteScoreNode)
    }
    func updateMilesFlownLabel() {
        // Remove old miles label if any
        self.childNode(withName: "milesFlownLabel")?.removeFromParent()
        // Calculate miles flown
        self.milesFlown = Int(scrollOffset / 10 / HelperFunctions.scaleFactor)
        let milesString = "\(milesFlown) miles"
        // Create the label using your sprite font
        let milesNode = HelperFunctions.writeTextWithSprites(milesString, charSize: CGSize(width: 14, height: 14), spacing: 1)
        for case let sprite as SKSpriteNode in milesNode.children {
            sprite.color = .gray
            sprite.colorBlendFactor = 1.0
        }
        // Position under the score label, right-aligned
        let scoreNode = self.childNode(withName: "spriteScoreLabel")
        let x = size.width - 50 - milesNode.calculateAccumulatedFrame().width
        let y = (scoreNode?.position.y ?? size.height - 120) - 14 * HelperFunctions.scaleFactor // 28px below score
        milesNode.position = CGPoint(x: x, y: y)
        milesNode.zPosition = 1000
        milesNode.name = "milesFlownLabel"
        addChild(milesNode)
    }
    
    func updateMissionNumberLabel() {
        // Remove old mission number label if any
        self.childNode(withName: "missionNumberLabel")?.removeFromParent()
        // Create the mission number string
        let missionString = String(format: "Mission %02d", currentMissionNumber)
        // Create the label using your sprite font
        let missionNode = HelperFunctions.writeTextWithSprites(missionString, charSize: CGSize(width: 14, height: 14), spacing: 1)
        for case let sprite as SKSpriteNode in missionNode.children {
            sprite.color = .gray
            sprite.colorBlendFactor = 1.0
        }
        // Position under the miles label, right-aligned
        let milesNode = self.childNode(withName: "milesFlownLabel")
        let x = size.width - 50 - missionNode.calculateAccumulatedFrame().width
        let y = (milesNode?.position.y ?? size.height - 148) - 9 * HelperFunctions.scaleFactor  // 18px below miles
        missionNode.position = CGPoint(x: x, y: y)
        missionNode.zPosition = 1000
        missionNode.name = "missionNumberLabel"
        addChild(missionNode)
    }
}
