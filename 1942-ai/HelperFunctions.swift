import SpriteKit
import AVFoundation

class HelperFunctions {
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

    // Call this once before using writeTextWithSprites
    static func loadFontSprites() {
        guard !isLoaded else { return }
        print("loading pixel font")
        guard let fontTexture = SKTexture(imageNamed: fontImageName) as SKTexture?, fontTexture.size().width > 0, fontTexture.size().height > 0 else {
            print("[HelperFunctions] ERROR: Font Pixels.png could not be loaded or has zero size. Check if the file exists in the bundle and is named correctly.")
            return
        }
        print("loaded pixel font")
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
        loadFontSprites()
        let node = SKNode()
        let upperText = text.uppercased()
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
            sprite.size = charSize
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: x, y: 0)
            node.addChild(sprite)
            x += charSize.width + spacing
        }
        return node
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
}


extension GameScene {
    
    // Add a helper function for bold fonts
    func boldFont(size: CGFloat) -> String {
        return "Courier-Bold"
    }

    // Update all font settings to use boldFont
    // Example:
    // label.fontName = boldFont(size: 22)
    
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
    
    func showExitPopup() { //Escape Button
        isGamePaused = true
        let popup = SKShapeNode(rectOf: CGSize(width: size.width * 0.4, height: size.height * 0.15), cornerRadius: 12)
        popup.fillColor = .black
        popup.alpha = 0.85
        popup.zPosition = 3000
        popup.name = "exitPopup"
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(popup)
        let label = SKLabelNode(text: "Leave the mission?")
        label.fontName = "Courier Bold"
        label.fontSize = 18
        label.position = CGPoint(x: 0, y: 22)
        label.zPosition = 3001
        popup.addChild(label)
        let leaveButton = SKLabelNode(text: "Leave")
        leaveButton.name = "leaveMission"
        leaveButton.fontName = "Courier-Bold"
        leaveButton.fontSize = 16
        leaveButton.fontColor = .red
        leaveButton.position = CGPoint(x: -50, y: -18)
        leaveButton.zPosition = 3001
        popup.addChild(leaveButton)
        let stayButton = SKLabelNode(text: "Stay")
        stayButton.name = "stayMission"
        stayButton.fontName = "Courier-Bold"
        stayButton.fontSize = 16
        stayButton.fontColor = .green
        stayButton.position = CGPoint(x: 50, y: -18)
        stayButton.zPosition = 3001
        popup.addChild(stayButton)
    }

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    // Show a red error dialog if the mission file is not found or is the wrong length
    func showMissionFileErrorDialog() {
        let popup = SKShapeNode(rectOf: CGSize(width: size.width * 0.5, height: size.height * 0.15), cornerRadius: 12)
        popup.fillColor = .red
        popup.alpha = 0.92
        popup.zPosition = 3000
        popup.name = "missionFileErrorPopup"
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(popup)
        let label = SKLabelNode(text: "Mission file not loading!")
        label.fontName = "Courier New"
        label.fontSize = 22
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 3001
        popup.addChild(label)
        // Add OK button for keyboard handling
        let okButton = SKLabelNode(text: "OK")
        okButton.name = "missionFileErrorOKButton"
        okButton.fontName = boldFont(size: 20)
        okButton.fontSize = 20
        okButton.fontColor = .green
        okButton.position = CGPoint(x: 0, y: -32)
        okButton.zPosition = 3001
        popup.addChild(okButton)
    }

    func showGameOverDialog() {
        isGamePaused = true
        let popup = SKShapeNode(rectOf: CGSize(width: size.width * 0.5, height: size.height * 0.22), cornerRadius: 16)
        popup.fillColor = .black
        popup.alpha = 0.92
        popup.zPosition = 3000
        popup.name = "gameOverPopup"
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(popup)
        let label = SKLabelNode(text: "Game Over! You died!")
        label.fontName = boldFont(size: 32)
        label.fontSize = 32
        label.fontColor = .red
        label.position = CGPoint(x: 0, y: 32)
        label.zPosition = 3001
        popup.addChild(label)
        let scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.fontName = boldFont(size: 22)
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: -8)
        scoreLabel.zPosition = 3001
        popup.addChild(scoreLabel)
        // Rename button for keyboard handling
        let okButton = SKLabelNode(text: "OK - Grrrr!")
        okButton.name = "gameOverOKButton"
        okButton.fontName = boldFont(size: 20)
        okButton.fontSize = 20
        okButton.fontColor = .green
        okButton.position = CGPoint(x: 0, y: -48)
        okButton.zPosition = 3001
        popup.addChild(okButton)
    }
    
    func showMissionCompletedDialog() {
        isGamePaused = true
        let popup = SKShapeNode(rectOf: CGSize(width: size.width * 0.5, height: size.height * 0.22), cornerRadius: 16)
        popup.fillColor = .black
        popup.alpha = 0.92
        popup.zPosition = 3000
        popup.name = "missionCompletedPopup"
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(popup)
        
        let label = SKLabelNode(text: "Mission completed!")
        label.fontName = boldFont(size: 28)
        label.fontSize = 28
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 32)
        label.zPosition = 3001
        popup.addChild(label)
        
        let scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.fontName = boldFont(size: 22)
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: -8)
        scoreLabel.zPosition = 3001
        popup.addChild(scoreLabel)
        
        let okButton = SKLabelNode(text: "OK")
        okButton.name = "missionCompletedOKButton"
        okButton.fontName = boldFont(size: 20)
        okButton.fontSize = 20
        okButton.fontColor = .green
        okButton.position = CGPoint(x: 0, y: -48)
        okButton.zPosition = 3001
        popup.addChild(okButton)
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
}
