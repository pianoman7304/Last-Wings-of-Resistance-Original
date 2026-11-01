import SpriteKit

class MissionEndScene: SKScene {
    // Data passed in from GameScene
    //var enemyKills: [String: Int] = [:] // Sprite filename -> kills
    var totalScoreBefore: Int = 0 // Score before this mission
    var missionScore: Int = 0 // Score for this mission
    var totalScoreAfter: Int = 0 // Changed from computed to stored property
    var isLastMission: Bool = false
    var enemyTypeOrder: [String] = [] // Order of enemy types (sprite filenames)
    var playerSpriteName: String = "me-01-an01.png" // Change if needed
    var okButton: SKNode?
    var dialogLabel: SKNode?
    var scoreLabel: SKNode?
    var playerIcon: SKSpriteNode?
    var totalScoreLabel: SKNode?
    var countUpSound: SKAction = SKAction.playSoundFileNamed("game-point-01.mp3", waitForCompletion: false)
    var victorySound: SKAction = SKAction.playSoundFileNamed("success-01.mp3", waitForCompletion: false)
    var currentCountIndex: Int = 0
    var currentScore: Int = 0
    var countUpTimer: Timer?
    var scoreCountUpTimer: Timer?
    var killsLabels: [SKNode] = []
    var killsIcons: [SKSpriteNode] = []
    var finishedCountingKills = false
    var finishedCountingScore = false
    var okButtonEnabled = false
    var currentMissionNumber: Int = 1
    var killsPerEnemyType: [String: Int] = [:]
    var playerDied: Bool = false

    override func didMove(to view: SKView) {
        ControllerInputHandler.shared.registerMissionEndScene(self)

        // Set up the scene size based on view dimensions. Default full screen, if too wide window modescoreLabel.text = "\(currentScore)"
        
       // Use end-mission.png as background instead of black
        let backgroundTexture = SKTexture(imageNamed: "end-mission.jpg")
        let backgroundSprite = SKSpriteNode(texture: backgroundTexture)
        backgroundSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundSprite.size = size
        backgroundSprite.zPosition = -1
        addChild(backgroundSprite)
        
        HelperFunctions.scaleFactor = size.width / HelperFunctions.preferredSceneSize.width  * 3.0 // Double the scale factor for larger images
        
        run(victorySound)
        // Ensure enemyTypeOrder is set from enemyTypeConfig if not already set
        if enemyTypeOrder.isEmpty {
            enemyTypeOrder = Array(enemyTypeConfig.keys)
        }
        // Ensure killsPerEnemyType is set from enemyKills if not already set
        for (enemyType, kills) in killsPerEnemyType {
            print("[MissionEndScene] Kills for \(enemyType): \(kills)")
        }
        //print("[MissionEndScene] Kills per enemy type: \(killsPerEnemyType)")
        setupEnemyIconsAndLabels()
        setupPlayerScoreDisplay()
     
        // Add 1 second wait before starting kills count up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startKillsCountUp()
        }
        
        // Add mission title at 30% from top, in gray
        let missionTitle = String(format: "Mission %02d", currentMissionNumber)
        let titleNode = HelperFunctions.writeTextWithSprites(missionTitle, charSize: CGSize(width: 32, height: 32), spacing: 2)
        let titleWidth = titleNode.calculateAccumulatedFrame().width
        titleNode.position = CGPoint(x: (size.width - titleWidth) / 2, y: size.height * 0.7)
        titleNode.zPosition = 20
        addChild(titleNode)
    }

    func setupEnemyIconsAndLabels() {
        // Layout enemy icons and labels in two rows, centered
        let iconSize = CGSize(width: 48, height: 48)
        let spacing: CGFloat = 52 // Spacing between icons
        let totalIcons = enemyTypeOrder.count
        let numRows = 2
        let iconsInFirstRow = (totalIcons + 1) / 2
        let iconsInSecondRow = totalIcons - iconsInFirstRow
        let firstRowYOffset: CGFloat = -40 // Move first row down by 40 points
        let yPositions = [size.height * 0.6 + firstRowYOffset, size.height * 0.4]
        killsLabels = []
        killsIcons = []
        var iconIndex = 0
        for row in 0..<numRows {
            let iconsThisRow = row == 0 ? iconsInFirstRow : iconsInSecondRow
            let totalWidth = CGFloat(iconsThisRow) * iconSize.width + CGFloat(iconsThisRow - 1) * spacing
            let startX = (size.width - totalWidth) / 2 + iconSize.width / 2
            let y = yPositions[row]
            for i in 0..<iconsThisRow {
                if iconIndex >= totalIcons { break }
                let enemyType = enemyTypeOrder[iconIndex]
                let x = startX + CGFloat(i) * (iconSize.width + spacing)
                let icon = SKSpriteNode(imageNamed: enemyType)
                icon.size = iconSize
                icon.position = CGPoint(x: x, y: y)
                icon.zPosition = 10
                addChild(icon)
                killsIcons.append(icon)
                // Start with 0 kills
                let label = HelperFunctions.writeTextWithSprites("0", charSize: CGSize(width: 24, height: 24), spacing: 2)
                label.position = CGPoint(x: x, y: y - iconSize.height * 0.7)
                label.zPosition = 10
                addChild(label)
                killsLabels.append(label)
                iconIndex += 1
            }
        }
    }

    func setupPlayerScoreDisplay() {
        // Player icon and score at bottom
        let iconSize = CGSize(width: 96, height: 96) // Changed from 48x48 to 96x96 (double size)
        let x = size.width * 0.5 - 300
        let y = size.height * 0.25
        playerIcon = SKSpriteNode(imageNamed: playerSpriteName)
        playerIcon?.size = iconSize
        playerIcon?.position = CGPoint(x: x, y: y)
        playerIcon?.zPosition = 10
        if let playerIcon = playerIcon {
            addChild(playerIcon)
        }
        // Player score label
        scoreLabel = HelperFunctions.writeTextWithSprites("", charSize: CGSize(width: 28, height: 28), spacing: 2)
        scoreLabel?.position = CGPoint(x: x + 80, y: y)
        scoreLabel?.zPosition = 10
        if let scoreLabel = scoreLabel {
            addChild(scoreLabel)
        }
        // Add total score label below player score
        totalScoreLabel = HelperFunctions.writeTextWithSprites("", charSize: CGSize(width: 28, height: 28), spacing: 2)
        if let totalScoreLabel = totalScoreLabel, let scoreLabel = scoreLabel {
            totalScoreLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 48)
            totalScoreLabel.zPosition = 10
            addChild(totalScoreLabel)
        }
    }

    func setupDialog() {
       
        let dialogText: String
        if playerDied {
            dialogText = "You died! Back to menu?"
        } else if isLastMission {
            dialogText = "All missions completed! Outstanding!"
        } else {
            dialogText = "Ready for next mission?"
        }
        dialogLabel = HelperFunctions.writeTextWithSprites(dialogText, charSize: CGSize(width: 24, height: 24), spacing: 2)
        // Center the dialog text properly
        let dialogWidth = dialogLabel?.calculateAccumulatedFrame().width ?? 0
        dialogLabel?.position = CGPoint(x: size.width * 0.5 - dialogWidth * 0.5, y: size.height * 0.1)
        dialogLabel?.zPosition = 20
        if let dialogLabel = dialogLabel {
            addChild(dialogLabel)
        }
        // OK button
        okButton = HelperFunctions.writeTextWithSprites("OK", charSize: CGSize(width: 32, height: 32), spacing: 2)
        // Center the OK button properly
        let okButtonWidth = okButton?.calculateAccumulatedFrame().width ?? 0
        okButton?.position = CGPoint(x: size.width * 0.5 - okButtonWidth * 0.5, y: size.height * 0.05)
        okButton?.zPosition = 20
        okButton?.name = "okButton"
        if let okButton = okButton {
            addChild(okButton)
            // Make OK button red like other dialogs
            for case let sprite as SKSpriteNode in okButton.children {
                sprite.color = .red
                sprite.colorBlendFactor = 1.0
            }
        }
        okButtonEnabled = false
        okButton?.alpha = 0.5 // Disabled until count up finishes
    }

    func startKillsCountUp() {
        currentCountIndex = 0
        countUpNextEnemyType()
    }

    func countUpNextEnemyType() {
        guard currentCountIndex < enemyTypeOrder.count else {
            finishedCountingKills = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startScoreCountUp()
            }
            return
        }
        let enemyType = enemyTypeOrder[currentCountIndex]
        let kills = killsPerEnemyType[enemyType] ?? 0
        var currentKills = 0
        let label = killsLabels[currentCountIndex]
        let countUpAction = SKAction.sequence([
            SKAction.run { [weak self] in
                if self != nil {
                    HelperFunctions.setTextForSpriteLabel(label, text: "0")
                }
            },
            SKAction.wait(forDuration: 0.2)
        ])
        label.run(countUpAction)
        let countUpTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in // Changed from 0.05 to 0.25 (5x slower)
            guard let self = self else { timer.invalidate(); return }
            if currentKills < kills {
                currentKills += 1
                HelperFunctions.setTextForSpriteLabel(label, text: "\(currentKills)")
                if (currentKills - 1) % 3 == 0 {
                        self.run(self.countUpSound)
                    }
            } else {
                timer.invalidate()
                self.currentCountIndex += 1
                self.countUpNextEnemyType()
            }
        }
        RunLoop.current.add(countUpTimer, forMode: .common)
    }

    func startScoreCountUp() {
        currentScore = 0//totalScoreBefore
        let targetScore = missionScore//totalScoreAfter
        totalScoreAfter = totalScoreBefore + missionScore // Store the total score after this mission
        // totalScoreBefore is set in the scene transition in HElperFunctions.transitionToGameScene
        
        print("Mission-Score: \(currentScore)", "Total-Score: \(targetScore)")
        let label = scoreLabel
        let scoreCountUpTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { [weak self] timer in // Changed from 0.01 to 0.001 (10x faster)
            guard let self = self else { timer.invalidate(); return }
            if self.currentScore == 0 { // show 0 score firsta dn in any case even if score is 0
                if let label = label {
                    HelperFunctions.setTextForSpriteLabel(label, text: "000000" + String(format: "  Mission %02d", currentMissionNumber))
                }
            }
             if self.currentScore < targetScore {
                self.currentScore += 1
                if let label = label {
                    HelperFunctions.setTextForSpriteLabel(label, text: String(format: "%06d", self.currentScore) + String(format: "  Mission %02d", currentMissionNumber))
                }
                // Only play sound every 250 points
                if self.currentScore % 250 == 0 {
                    self.run(self.countUpSound)
                }
            } else {
                timer.invalidate()
                self.finishedCountingScore = true
                // Add 1 second break after score counting, then show total score and play another victory sound
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let totalScoreLabel = self.totalScoreLabel {
                        HelperFunctions.setTextForSpriteLabel(totalScoreLabel, text: String(format: "%06d", self.totalScoreAfter) + "  All Missions")
                    }
                    self.run(self.victorySound)
                    // Add another 1 second pause before showing dialog and enabling OK button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.setupDialog()
                        self.enableOkButton()
                    }
                }
            }
        }
        RunLoop.current.add(scoreCountUpTimer, forMode: .common)
    }

    func enableOkButton() {
        okButtonEnabled = true
        okButton?.alpha = 1.0
    }

#if os(macOS)
    override func mouseDown(with event: NSEvent) {
        guard okButtonEnabled else { return }
        let location = event.location(in: self)
        if let okButton = okButton, okButton.contains(location) {
            handleOkButton()
        }
    }

    override func keyDown(with event: NSEvent) {
        guard okButtonEnabled else { return }
        if event.keyCode == 36 || event.keyCode == 49 { // Return or Space
            handleOkButton()
        }
    }
#elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard okButtonEnabled else { return }
        let location = touches.first?.location(in: self) ?? .zero
        if let okButton = okButton, okButton.contains(location) {
            handleOkButton()
        }
    }
#endif

    func handleOkButton() {
        if playerDied || isLastMission {
            // Go to main menu
            if let view = self.view {
                HelperFunctions.transitionToMainMenuScene(from: view)
                
            }
        } else {
            // Go to next mission
            if let view = self.view {
                HelperFunctions.transitionToGameScene(from: view, missionNumber: getNextMissionNumber(), priorMissionsScore: totalScoreAfter)
                
            }
        }
    }

    func getNextMissionNumber() -> Int {
        // Return the next mission number
        return currentMissionNumber + 1
    }

    // Controller navigation: called by controller A/B button
    func controllerNavigate() {
        // Simulate OK button tap or advance
        if okButtonEnabled {
            if playerDied || isLastMission {
                // Go to main menu
                if let view = self.view {
                    HelperFunctions.transitionToMainMenuScene(from: view)
                    
                }
            } else {
                // Go to next mission
                if let view = self.view {
                    HelperFunctions.transitionToGameScene(from: view, missionNumber: getNextMissionNumber(), priorMissionsScore: totalScoreAfter)
                    
                }
            }
        }
    }
}
