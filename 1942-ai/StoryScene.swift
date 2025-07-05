import SpriteKit

class StoryScene: SKScene {
    let storyImages = ["story1of3E", "story2of3E", "story3of3E"]
    var currentIndex = 0
    var imageNode: SKSpriteNode?
    var nextButton: SKLabelNode?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        showCurrentImage()
        addNextButton()
    }

    func showCurrentImage() {
        imageNode?.removeFromParent()
        let imageName = storyImages[currentIndex]
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.position = CGPoint(x: size.width/2, y: size.height/2)
        sprite.zPosition = 1
        // Scale to 100% of the screen, maintaining aspect ratio
        let scaleX = size.width / sprite.size.width
        let scaleY = size.height / sprite.size.height
        sprite.setScale(min(scaleX, scaleY))
        addChild(sprite)
        imageNode = sprite
    }

    func addNextButton() {
        nextButton?.removeFromParent()
        let button = SKLabelNode(text: "Next")
        button.fontName = "Courier-Bold"
        button.fontSize = 32
        button.position = CGPoint(x: size.width - 80, y: 60)
        button.zPosition = 2
        button.name = "nextButton"
        addChild(button)
        nextButton = button
    }

    func goToNext() {
        if currentIndex < storyImages.count - 1 {
            currentIndex += 1
            showCurrentImage()
        } else {
            // Return to main menu
            if let view = self.view {
                let menu = MainMenuScene(size: CGSize(width: 1024, height: 640))
                menu.scaleMode = .aspectFill
                view.presentScene(menu, transition: SKTransition.fade(withDuration: 1.0))
                // Ensure window stays in full screen after scene transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let window = view.window, !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { // Space bar
            goToNext()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "nextButton" {
                goToNext()
            }
        }
    }
}
