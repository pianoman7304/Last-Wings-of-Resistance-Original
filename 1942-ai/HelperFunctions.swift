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

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    // Show a red error dialog if the mission file is not found or is the wrong length
    func showMissionFileErrorDialog() {
        let dialogNode = HelperFunctions.createCustomDialog(question: "Mission file not loading!", options: ["OK"])
        dialogNode.name = "missionFileErrorPopup"
        showCustomDialog(node: dialogNode, options: ["OK"])
    }

    func showGameOverDialog() {
        let dialogNode = HelperFunctions.createCustomDialog(question: "Game Over! You died!", options: ["OK"])
        dialogNode.name = "gameOverPopup"
        showCustomDialog(node: dialogNode, options: ["OK"])
    }
    
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
}
