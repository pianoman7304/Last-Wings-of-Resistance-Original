import SpriteKit
import AppKit
import AVFoundation

class MainMenuScene: SKScene {
    var buttonNodes: [SKLabelNode] = []
    var originalColors: [SKLabelNode: SKColor] = [:]
    
    var intelWindow: NSWindow?
    var controlsWindow: NSWindow?
    
    var backgroundMusicPlayer: AVAudioPlayer?
    
    var menuSpriteNodes: [SKNode] = []
    var selectedMenuIndex: Int = 0

    override func didMove(to view: SKView) {
        // Remove all full screen logic from main menu scene
        let bg = SKSpriteNode(imageNamed: "start-page.png")
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.size = size
        bg.zPosition = -1
        addChild(bg)
        backgroundColor = .black
        createMenu()
        playBackgroundMusic()
        
        // Add game title at the top using writeTextWithSprites
        let titleNode = HelperFunctions.writeTextWithSprites("Last Wings of the Resistance", charSize: CGSize(width: 24, height: 24), spacing: 2.0)
        titleNode.position = CGPoint(x: 50, y: size.height - 120)
        titleNode.zPosition = 10
        addChild(titleNode)
        
        // Select the first menu item by default
        selectedMenuIndex = 0
        updateMenuSelection()
    }

    func createMenu() {
        // Remove old menu nodes if any
        for node in menuSpriteNodes { node.removeFromParent() }
        menuSpriteNodes.removeAll()
        // Button titles in order
        let buttonTitles = ["Take off!", "Intel", "Story", "Controls", "Quit"]
        let buttonNames = ["newGame", "intel", "story", "controls", "quit"]
        let buttonSpacing: CGFloat = 60 // vertical spacing between buttons
        let startY = size.height - 200 // starting Y position for the first button
        for (i, title) in buttonTitles.enumerated() {
            let spriteNode = HelperFunctions.writeTextWithSprites(title, charSize: CGSize(width: 19, height: 19), spacing: 1.6)
            spriteNode.position = CGPoint(x: 50, y: startY - CGFloat(i) * buttonSpacing)
            spriteNode.name = buttonNames[i]
            addChild(spriteNode)
            menuSpriteNodes.append(spriteNode)
        }
    }

    func updateMenuSelection() {
        for (i, node) in menuSpriteNodes.enumerated() {
            node.alpha = (i == selectedMenuIndex) ? 0.6 : 1.0
        }
    }

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

    func handleMenuSelection() {
        let selectedNode = menuSpriteNodes[selectedMenuIndex]
        switch selectedNode.name {
        case "newGame":
            if let view = self.view {
                stopBackgroundMusic()
                let designSize = CGSize(width: 1024, height: 640)
                let scene = GameScene(size: designSize)
                scene.scaleMode = .aspectFill
                view.presentScene(scene, transition: SKTransition.fade(withDuration: 1.0))
            }
        case "intel":
            presentIntelScene()
        case "story":
            presentStoryScene()
        case "controls":
            presentControlsScene()
        case "quit":
            stopBackgroundMusic()
            NSApplication.shared.terminate(nil)
        default:
            break
        }
    }
    
    func showImageWindow(imageName: String, title: String, windowType: String) {
        // Load the image using only the filename from the bundle
        guard let img = NSImage(named: imageName) else {
            let alert = NSAlert()
            alert.messageText = "Image not found: \(imageName)"
            alert.runModal()
            return
        }
        // Double the image size for the window and image view
        let imageSize = NSSize(width: img.size.width * 2, height: img.size.height * 2)
        let closeButtonHeight: CGFloat = 40
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height + closeButtonHeight))
        let imageView = NSImageView(image: img)
        imageView.frame = NSRect(x: 0, y: closeButtonHeight, width: imageSize.width, height: imageSize.height)
        imageView.imageScaling = .scaleAxesIndependently
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeImageWindow(_:)))
        closeButton.frame = NSRect(x: 10, y: 5, width: 80, height: 30)
        contentView.addSubview(imageView)
        contentView.addSubview(closeButton)
        let window = NSWindow(contentRect: contentView.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.contentView = contentView
        window.title = title
        window.level = .floating
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false // Prevent deallocation
        if windowType == "intel" {
            intelWindow = window
        } else if windowType == "controls" {
            controlsWindow = window
        }
    }

    @objc func closeImageWindow(_ sender: Any?) {
        if let button = sender as? NSButton, let window = button.window {
            window.orderOut(nil)
            if window == intelWindow { intelWindow = nil }
            if window == controlsWindow { controlsWindow = nil }
        }
    }
    
    // Add a helper function for bold fonts
    func boldFont(size: CGFloat) -> String {
        return "Courier-Bold"
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
    
    func presentStoryScene() {
        if let view = self.view {
            stopBackgroundMusic()
            let scene = StoryScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            view.presentScene(scene, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
    func presentIntelScene() {
        if let view = self.view {
            stopBackgroundMusic()
            let scene = InfoImageScene(size: view.bounds.size, imageName: "intel.png", title: "Intel")
            scene.scaleMode = .aspectFill
            view.presentScene(scene, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
    func presentControlsScene() {
        if let view = self.view {
            stopBackgroundMusic()
            let scene = InfoImageScene(size: view.bounds.size, imageName: "controls.png", title: "Controls")
            scene.scaleMode = .aspectFill
            view.presentScene(scene, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
}
