import SpriteKit

class ImageSequenceScene: SKScene {
    let imageNames: [String]
    var currentIndex = 0
    var imageNode: SKSpriteNode?

    // Initialize with a list of image names
    init(size: CGSize, imageNames: [String]) {
        self.imageNames = imageNames
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        ControllerInputHandler.shared.registerImageSequenceScene(self) // Reuse registration for navigation
        backgroundColor = .black
        showCurrentImage()
    }

    func showCurrentImage() {
        imageNode?.removeFromParent()
        let imageName = imageNames[currentIndex]
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

    func goToNext() {
        if currentIndex < imageNames.count - 1 {
            currentIndex += 1
            showCurrentImage()
        } else {
            // Return to main menu
            if let view = self.view {
                let menu = MainMenuScene(size: HelperFunctions.preferredSceneSize)
                menu.scaleMode = .aspectFit
                view.presentScene(menu, transition: SKTransition.fade(withDuration: 1.0))
            }
        }
    }

    // Controller navigation: called by controller A/B button
    func controllerNavigate() {
        goToNext()
    }

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 53 || event.keyCode == 36 { // Space bar or Escape or Enter
            goToNext()
        }
    }

    override func mouseDown(with event: NSEvent) {
        goToNext()
    }
    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        goToNext()
    }
    #endif
}
