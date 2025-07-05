import SpriteKit

class InfoImageScene: SKScene {
    let imageName: String
    let infoTitle: String
    var imageNode: SKSpriteNode?
    
    init(size: CGSize, imageName: String, title: String) {
        self.imageName = imageName
        self.infoTitle = title
        // Always use fixed design resolution for InfoImageScene
        let fixedSize = CGSize(width: 1024, height: 640)
        super.init(size: fixedSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        // Always use fixed design resolution for InfoImageScene
        self.size = CGSize(width: 1024, height: 640)
        backgroundColor = .black
        showImage()
    }
    
    func showImage() {
        imageNode?.removeFromParent()
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.position = CGPoint(x: size.width/2, y: size.height/2)
        sprite.zPosition = 1
        let scaleX = size.width / sprite.size.width
        let scaleY = size.height / sprite.size.height
        sprite.setScale(min(scaleX, scaleY))
        addChild(sprite)
        imageNode = sprite
    }
    
    func goBackToMenu() {
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
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 53 { // Space bar or Escape
            goBackToMenu()
        }
    }
}
