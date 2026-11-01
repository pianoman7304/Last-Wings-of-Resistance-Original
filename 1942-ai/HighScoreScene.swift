import SpriteKit

class HighScoreScene: SKScene {
    override func didMove(to view: SKView) {
        // Background
        let bg = SKSpriteNode(imageNamed: "highscores.jpg")
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.size = size
        bg.zPosition = -1
        addChild(bg)

        // Title
        let titleNode = HelperFunctions.writeTextWithSprites("Top 100 Pilots", charSize: CGSize(width: 24, height: 24), spacing: 2.0)
        titleNode.position = CGPoint(x: size.width/2 - titleNode.frame.width/2, y: size.height - 100)
        addChild(titleNode)

        // High score list
        let scores = HighScoreManager.shared.scores
        let startY = size.height - 160
        let lineHeight: CGFloat = 28
        for (i, entry) in scores.prefix(100).enumerated() {
            let line = String(format: "#%02d  %-6s  %6d", i+1, entry.name, entry.score)
            let lineNode = HelperFunctions.writeTextWithSprites(line, charSize: CGSize(width: 16, height: 16), spacing: 1.2)
            lineNode.position = CGPoint(x: size.width/2 - lineNode.frame.width/2, y: startY - CGFloat(i) * lineHeight)
            addChild(lineNode)
        }
    }
    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 || event.keyCode == 49 || event.keyCode == 36 { // Escape, Space, Return
            if let view = self.view {
                let menu = MainMenuScene(size: HelperFunctions.preferredSceneSize)
                menu.scaleMode = .aspectFit //.aspectFill
                view.presentScene(menu, transition: SKTransition.fade(withDuration: 1.0))
            }
        }
    }
    #endif
    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = self.view {
            let menu = MainMenuScene(size: HelperFunctions.preferredSceneSize)
            menu.scaleMode = .aspectFit //.aspectFill
            view.presentScene(menu, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
    #endif
}
