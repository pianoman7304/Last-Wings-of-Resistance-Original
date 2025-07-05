import SpriteKit
import AVFoundation

class GameScene: SKScene {
    // --- Gameplay properties ---
    let tileSize = CGSize(width: 64, height: 64)
    let mapWidth = 8
    let mapHeight = 75 // Mission file rows
    let visibleRows = 8
    var missionTileGrid: [[Character]] = []
    var tileImages: [SKTexture] = []
    var tileNodes: [[SKSpriteNode?]] = []
    var currentRow = 0
    let playerSpeed: CGFloat = 250
    var player: SKSpriteNode!
    var playerFrames: [SKTexture] = []
    var moveDirection: CGVector = .zero
    let bulletSpeed: CGFloat = 128
    var bullets: [SKNode] = []
    let scrollSpeed: CGFloat = 32
    var scrollOffset: CGFloat = 0
    var lastUpdateTime: TimeInterval = 0
    var score: Int = 0
    var scoreLabel: SKLabelNode!
    var enemyPlanes: [EnemyPlane] = []
    let enemyPlaneFilenames: [String] = [
        "00139.png", "00140.png", "00250.png", "00260.png", "00270.png", "00280.png", "00290.png", "00300.png", "00310.png", "00320.png", "00330.png", "00340.png", "00350.png", "00355.png", "00360.png", "00410.png", "00450.png", "00500.png"
    ]
    var enemyPlaneTextures: [SKTexture] = []
    let maxEnemies = 5
    let enemySpeed: CGFloat = 64
    let enemyHorizontalSpeed: CGFloat = 32
    var lastEnemySpawnTime: TimeInterval = 0
    var nextEnemySpawnDelay: Double = 0
    var backgroundMusicPlayer: AVAudioPlayer?
    var isGamePaused = false
    var playerLives: Int = 3
    var heartNodes: [SKSpriteNode] = []
    var bonusFrames: [[SKTexture]] = [] // [row][frame]
    var lastBonusSpawnTime: TimeInterval = 0
    let bonusRows = 7
    let bonusCols = 6
    let bonusFramesPerRow = [6, 4, 6, 6, 6, 6, 4] // row 2 and 7 have 4 frames, others 6
    var playerHealthBar: SKSpriteNode!
    var playerHealth: Int = 100
    var lastRocketFireTime: TimeInterval = 0
    var nextBonusSpawnTime: TimeInterval = 0
    var activeBonus: SKSpriteNode?
    var bonusSpawnCount: Int = 0

    override func didMove(to view: SKView) {
        // Make window full screen if not already
        if let window = view.window, !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
        loadMissionFile()
        loadTileAtlas()
        setupMissionTiles()
        setupPlayer()
        setupScoreLabel()
        // Initialize enemy textures
        enemyPlaneTextures = enemyPlaneFilenames.compactMap { SKTexture(imageNamed: $0) }
        lastUpdateTime = 0
        self.isUserInteractionEnabled = true
        playBackgroundMusic()
        loadBonusSprites()
        setupHeartsDisplay()
        setupPlayerHealthBar()
        // Show Mission Start! in the middle of the screen using sprite font
        let missionStartNode = HelperFunctions.writeTextWithSprites("Mission Start!", charSize: CGSize(width: 36, height: 36), spacing: 4)
        missionStartNode.position = CGPoint(x: size.width/2 - missionStartNode.calculateAccumulatedFrame().width/2, y: size.height/2)
        missionStartNode.zPosition = 2002
        missionStartNode.name = "missionStartText"
        addChild(missionStartNode)
        // Remove after 3 seconds
        missionStartNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    override func willMove(from view: SKView) {
        stopBackgroundMusic()
    }

    // Loads the mission file and parses it into a 2D array of tile characters
    func loadMissionFile() {
        // Find all mission files in the bundle matching "Mission ".
        let missionFiles = Bundle.main.paths(forResourcesOfType: "txt", inDirectory: nil)
            .filter { $0.contains("Mission ") }
        let missionNames = missionFiles.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        let selectedMission = missionNames.randomElement() ?? "Mission 04"
        let missionPath = Bundle.main.path(forResource: selectedMission, ofType: "txt")
        guard let path = missionPath, let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            showMissionFileErrorDialog()
            missionTileGrid = Array(repeating: Array(repeating: "A", count: mapWidth), count: mapHeight)
            return
        }
        // Check for correct length (8x75 = 600)
        if text.count != 600 {
            showMissionFileErrorDialog()
            missionTileGrid = Array(repeating: Array(repeating: "A", count: mapWidth), count: mapHeight)
            return
        }
        let columns = mapWidth
        let rows = mapHeight
        var grid: [[Character]] = Array(repeating: Array(repeating: "A", count: columns), count: rows)
        for i in 0..<min(text.count, columns * rows) {
            let row = i / columns
            let col = i % columns
            let idx = text.index(text.startIndex, offsetBy: i)
            grid[rows - 1 - row][col] = text[idx]
        }
        missionTileGrid = grid
        // Debug output: print the missionTileGrid as characters
        print("missionTileGrid loaded:")
        for row in 0..<rows {
            let line = String(missionTileGrid[row])
            print(line)
        }
    }

    

    // Loads the tile atlas and cuts it into 16 tiles (4x4), flipping y-axis to match editor
    func loadTileAtlas() {
        let atlasTexture = SKTexture(imageNamed: "Landscape-Atlas-01.png")
        tileImages = []
        let tileCount = 4
        let atlasSize = atlasTexture.size()
        let subTileSize = CGSize(width: atlasSize.width / CGFloat(tileCount), height: atlasSize.height / CGFloat(tileCount))
        for y in 0..<tileCount {
            let flippedY = tileCount - 1 - y
            for x in 0..<tileCount {
                let rect = CGRect(
                    x: CGFloat(x) * subTileSize.width / atlasSize.width,
                    y: CGFloat(flippedY) * subTileSize.height / atlasSize.height,
                    width: subTileSize.width / atlasSize.width,
                    height: subTileSize.height / atlasSize.height
                )
                let tileTexture = SKTexture(rect: rect, in: atlasTexture)
                tileImages.append(tileTexture)
            }
        }
    }

    // Sets up the visible mission tiles as SKSpriteNodes, scaling to full screen width (no y-flip)
    func setupMissionTiles() {
        for row in tileNodes { for node in row { node?.removeFromParent() } }
        tileNodes = Array(repeating: Array(repeating: nil, count: mapWidth), count: visibleRows)
        let screenWidth = size.width
        let scaledTileWidth = screenWidth / CGFloat(mapWidth)
        let scaledTileHeight = tileSize.height * (scaledTileWidth / tileSize.width)
        let scaledTileSize = CGSize(width: scaledTileWidth, height: scaledTileHeight)
        for row in 0..<visibleRows {
            for col in 0..<mapWidth {
                let tileChar = missionTileGrid[row][col]
                let tileIdx = tileIndex(for: tileChar)
                let tileTexture = tileIdx < tileImages.count ? tileImages[tileIdx] : nil
                let node = SKSpriteNode(texture: tileTexture)
                node.size = scaledTileSize
                node.anchorPoint = CGPoint(x: 0, y: 0)
                node.position = CGPoint(x: CGFloat(col) * scaledTileWidth, y: CGFloat(row) * scaledTileHeight)
                node.zPosition = -10
                addChild(node)
                tileNodes[row][col] = node
            }
        }
    }

    // Helper to map tile char (A-P) to index
    func tileIndex(for char: Character) -> Int {
        let ascii = Int(char.asciiValue ?? 65)
        return max(0, min(15, ascii - 65))
    }

    // Updates the visible tiles based on scrollOffset, scaling to full screen width (no y-flip)
    func updateVisibleMissionTiles() {
        let screenWidth = size.width
        let scaledTileWidth = screenWidth / CGFloat(mapWidth)
        let scaledTileHeight = tileSize.height * (scaledTileWidth / tileSize.width)
        let firstRow = Int(scrollOffset / scaledTileHeight)
        let yOffset = scrollOffset.truncatingRemainder(dividingBy: scaledTileHeight)
        for row in 0..<visibleRows {
            let missionRow = firstRow + row
            for col in 0..<mapWidth {
                if missionRow >= 0 && missionRow < missionTileGrid.count {
                    let tileChar = missionTileGrid[missionRow][col]
                    let tileIdx = tileIndex(for: tileChar)
                    let node = tileNodes[row][col]
                    node?.texture = tileIdx < tileImages.count ? tileImages[tileIdx] : nil
                    node?.position = CGPoint(x: CGFloat(col) * scaledTileWidth, y: CGFloat(row) * scaledTileHeight - yOffset)
                    node?.size = CGSize(width: scaledTileWidth, height: scaledTileHeight)
                    node?.isHidden = false
                } else {
                    tileNodes[row][col]?.isHidden = true
                }
            }
        }
    }

    func setupPlayer() {
        let frameNames = ["me-01-an01.png", "me-01-an02.png", "me-01-an03.png", "me-01-an04.png"]
        // Try loading from just the filename (since all sprites are in the bundle)
        playerFrames = frameNames.compactMap { SKTexture(imageNamed: $0) }
        if playerFrames.isEmpty {
            print("Player sprite frames not found! Check that me-01-an01.png etc. are in the bundle.")
            player = SKSpriteNode(color: .red, size: tileSize)
        } else {
            player = SKSpriteNode(texture: playerFrames.first)
            player.size = tileSize
            player.position = CGPoint(x: size.width/2, y: tileSize.height * 2)
            addChild(player)
            player.run(SKAction.repeatForever(SKAction.animate(with: playerFrames, timePerFrame: 0.1)))
        }
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

    // --- Enemy plane logic ---
    func spawnEnemyPlanes() { /* removed, now using smart version */ }
    func updateEnemyPlanes(_ dt: CGFloat) { /* removed, now using smart version */ }
    func checkBulletEnemyCollisions() { /* removed, now using smart version */ }

    func checkBulletEnemyCollisionsSmart() {
        var bulletsToRemove: [SKSpriteNode] = []
        var rocketsToRemove: [SKSpriteNode] = []
        for enemy in enemyPlanes {
            for bullet in children {
                // Player bullets
                if bullet.name == nil { continue }
                if bullet.name == "playerRocket" {
                    if let rocketNode = bullet as? SKSpriteNode, rocketNode.frame.intersects(enemy.frame) {
                        // Rocket does 10 damage
                        enemy.health -= 10
                        rocketsToRemove.append(rocketNode)
                        if enemy.health <= 0 {
                            // Score calculation: health * moveSpeed / 10 * shotsAtOnce
                            let points = Int(round(Double(enemy.initialHealth) * Double(enemy.moveSpeed) / 10.0 * Double(enemy.shotsAtOnce)))
                            score += points
                            updateScoreLabel()
                            explodeEnemy(enemy)
                            if let idx = enemyPlanes.firstIndex(of: enemy) { enemyPlanes.remove(at: idx) }
                        }
                        break
                    }
                } else if bullet.name == "bullet" || bullet.name == "playerBullet" || bullet.name == "leftBullet" || bullet.name == "rightBullet" {
                    if let bulletNode = bullet as? SKSpriteNode, bulletNode.frame.intersects(enemy.frame) {
                        // Bullet does 1 damage
                        enemy.health -= 1
                        bulletsToRemove.append(bulletNode)
                        if enemy.health <= 0 {
                            // Score calculation: health * moveSpeed / 10 * shotsAtOnce
                            let points = Int(round(Double(enemy.initialHealth) * Double(enemy.moveSpeed) / 10.0 * Double(enemy.shotsAtOnce)))
                            score += points
                            updateScoreLabel()
                            explodeEnemy(enemy)
                            if let idx = enemyPlanes.firstIndex(of: enemy) { enemyPlanes.remove(at: idx) }
                        }
                        break
                    }
                }
            }
        }
        for bullet in bulletsToRemove { bullet.removeFromParent() }
        for rocket in rocketsToRemove { rocket.removeFromParent() }
    }

    func explodeEnemy(_ enemy: SKSpriteNode) {
        // Comment out the SKEmitterNode explosion
        // if let emitter = SKEmitterNode(fileNamed: "Explosion.sks") {
        //     emitter.position = enemy.position
        //     emitter.zPosition = 20
        //     addChild(emitter)
        //     emitter.run(SKAction.sequence([
        //         SKAction.wait(forDuration: 0.5),
        //         SKAction.removeFromParent()
        //     ]))
        // }
        // Play explosion sound
        let sound = SKAction.playSoundFileNamed("explosion-02.mp3", waitForCompletion: false)
        run(sound)
        // Use sprite-based explosion animation
        runExplosionAnimation(at: enemy.position, in: self, size: CGSize(width: enemy.size.width * 1.2, height: enemy.size.height * 1.2))
        enemy.removeFromParent()
    }

    func showPlayerExplosion(at position: CGPoint) {
        // Use the same explosion animation as enemy planes, but ensure it's above the player
        runExplosionAnimation(at: position, in: self, size: CGSize(width: player.size.width * 1.2, height: player.size.height * 1.2), zPosition: player.zPosition + 1)
    }

    // --- Bonus logic ---
    func scheduleNextBonusSpawn(currentTime: TimeInterval) {
        nextBonusSpawnTime = currentTime + Double.random(in: 5.0...10.0)
    }

    func spawnRandomBonus() {
        guard activeBonus == nil else { return } // Only one bonus at a time
        bonusSpawnCount += 1
        let isAddLife = bonusSpawnCount % 5 == 0
        let bonusType = isAddLife ? 2 : 3 // 2nd (addLife) every 5th, otherwise 3rd (fullHealth)
        let bonusFramesArr = bonusType == 2 ? (bonusFrames.count > 1 ? bonusFrames[1] : []) : (bonusFrames.count > 2 ? bonusFrames[2] : [])
        let frameCount = bonusFramesArr.count
        guard frameCount > 0 else { return }
        let bonus = SKSpriteNode(texture: bonusFramesArr.first)
        bonus.size = CGSize(width: 48, height: 48)
        let x = CGFloat.random(in: 60...(size.width-60))
        let y = size.height + 40
        bonus.position = CGPoint(x: x, y: y)
        bonus.zPosition = 1200
        bonus.name = isAddLife ? "addLife" : "fullHealth"
        addChild(bonus)
        activeBonus = bonus
        // Animate
        let animate = SKAction.repeatForever(SKAction.animate(with: bonusFramesArr, timePerFrame: 0.15))
        bonus.run(animate)
        // Move down
        let moveDown = SKAction.moveTo(y: -60, duration: 6.0)
        let remove = SKAction.run { [weak self] in self?.activeBonus = nil; bonus.removeFromParent() }
        bonus.run(SKAction.sequence([moveDown, remove]))
    }

    func checkPlayerBonusCollisions() {
        guard let bonus = activeBonus else { return }
        if player.frame.intersects(bonus.frame) {
            if bonus.name == "addLife" {
                playerLives += 1
                setupHeartsDisplay()
                let sound = SKAction.playSoundFileNamed("game-point-02.mp3", waitForCompletion: false)
                run(sound)
            } else if bonus.name == "fullHealth" {
                playerHealth = 100
                updatePlayerHealthBar()
                let sound = SKAction.playSoundFileNamed("game-point-01.mp3", waitForCompletion: false)
                run(sound)
            }
            bonus.removeFromParent()
            activeBonus = nil
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if isGamePaused {
            lastUpdateTime = currentTime
            return
        }
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        scrollOffset += scrollSpeed * CGFloat(dt)
        let maxOffset = CGFloat(mapHeight - visibleRows) * tileSize.height
        if scrollOffset > maxOffset {
            scrollOffset = maxOffset
        }
        updateVisibleMissionTiles()
        // Show mission completed dialog if at end
        if scrollOffset >= maxOffset && self.childNode(withName: "missionCompletedPopup") == nil {
            showMissionCompletedDialog()
            return
        }
        // Smooth player movement with diagonal normalization
        if moveDirection != .zero {
            var direction = moveDirection
            if abs(direction.dx) > 0 && abs(direction.dy) > 0 {
                let scale = 1.0 / sqrt(2.0)
                direction.dx *= scale
                direction.dy *= scale
            }
            let moveAmount = playerSpeed * CGFloat(dt)
            let dx = direction.dx * moveAmount
            let dy = direction.dy * moveAmount
            var newPosition = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
            // Clamp player position to visible mission tile area
            let minX = player.size.width / 2
            let maxX = size.width - player.size.width / 2
            let minY = player.size.height / 2
            let maxY = tileSize.height * CGFloat(visibleRows) - player.size.height / 2
            newPosition.x = max(minX, min(newPosition.x, maxX))
            newPosition.y = max(minY, min(newPosition.y, maxY))
            player.position = newPosition
        }
        // --- Enemy and bullet update logic ---
        updateEnemyPlanesSmart(CGFloat(dt), currentTime: currentTime)
        checkBulletEnemyCollisionsSmart()
        checkPlayerEnemyCollisions()
        checkPlayerBulletCollisions()
        // Spawn new set if all gone and enough time passed
        if enemyPlanes.isEmpty {
            if nextEnemySpawnDelay <= 0 {
                nextEnemySpawnDelay = Double.random(in: 1.0...3.0)
                lastEnemySpawnTime = currentTime
            } else if currentTime - lastEnemySpawnTime > nextEnemySpawnDelay {
                spawnEnemyPlanesSmart()
                nextEnemySpawnDelay = 0
            }
        }
        // Bonus logic: spawn and check collisions
        if currentTime >= nextBonusSpawnTime {
            spawnRandomBonus()
            scheduleNextBonusSpawn(currentTime: currentTime)
        }
        checkPlayerBonusCollisions()
    }

    

    func shootBullets() {
        // Bullet properties
        let bulletImage = "FastBullet1.png"
        let bulletScale: CGFloat = 1.0
        let bulletSpeed: CGFloat = scrollSpeed * 4
        let bulletYOffset: CGFloat = player.size.height / 2
        let bulletXOffset: CGFloat = player.size.width * 0.22
        // Use SKSpriteNode directly since FastBullet1.png has alpha
        let leftBullet = SKSpriteNode(imageNamed: bulletImage)
        leftBullet.setScale(bulletScale)
        leftBullet.position = CGPoint(x: player.position.x - bulletXOffset, y: player.position.y + bulletYOffset)
        leftBullet.zPosition = 10
        leftBullet.name = "leftBullet"
        addChild(leftBullet)
        let rightBullet = SKSpriteNode(imageNamed: bulletImage)
        rightBullet.setScale(bulletScale)
        rightBullet.position = CGPoint(x: player.position.x + bulletXOffset, y: player.position.y + bulletYOffset)
        rightBullet.zPosition = 10
        rightBullet.name = "rightBullet"
        addChild(rightBullet)
        // Move bullets up and remove when off screen
        let moveDistance = size.height + 100
        let moveDuration = Double(moveDistance) / Double(bulletSpeed)
        let moveAction = SKAction.moveBy(x: 0, y: moveDistance, duration: moveDuration)
        let removeAction = SKAction.removeFromParent()
        leftBullet.run(SKAction.sequence([moveAction, removeAction]))
        rightBullet.run(SKAction.sequence([moveAction, removeAction]))
        // Play shooting sound
        let sound = SKAction.playSoundFileNamed("shake.caf", waitForCompletion: false)
        run(sound)
    }

    func shootRocket() {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastRocketFireTime < 1.0 { return } // 1 rocket per second
        lastRocketFireTime = currentTime
        let rocketTexture = SKTexture(imageNamed: "RedRocket.png")
        let rocket = SKSpriteNode(texture: rocketTexture)
        rocket.position = player.position
        rocket.setScale(1.0)
        // Set zPosition just below the player
        rocket.zPosition = player.zPosition - 1
        rocket.name = "playerRocket"
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: size.height + rocket.size.height), duration: 2.0)
        let removeAction = SKAction.removeFromParent()
        rocket.run(SKAction.sequence([moveAction, removeAction]))
        addChild(rocket)
        let sound = SKAction.playSoundFileNamed("laser_ship.caf", waitForCompletion: false)
        run(sound)
    }

    override func keyDown(with event: NSEvent) {
        // Dialog handling: allow space/return/enter for OK, escape for stay in exit dialog
        if let missionError = self.childNode(withName: "missionFileErrorPopup"), missionError.isHidden == false {
            if event.keyCode == 49 || event.keyCode == 36 { // Space or Return
                self.childNode(withName: "missionFileErrorOKButton")?.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.run { missionError.removeFromParent() }
                ]))
                return
            }
        }
        if let gameOver = self.childNode(withName: "gameOverPopup"), gameOver.isHidden == false {
            if event.keyCode == 49 || event.keyCode == 36 { // Space or Return
                self.childNode(withName: "gameOverOKButton")?.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.run { gameOver.removeFromParent() }
                ]))
                return
            }
        }
        if let missionCompleted = self.childNode(withName: "missionCompletedPopup"), missionCompleted.isHidden == false {
            if event.keyCode == 49 || event.keyCode == 36 { // Space or Return
                self.childNode(withName: "missionCompletedOKButton")?.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.run { missionCompleted.removeFromParent() }
                ]))
                return
            }
        }
        if let exitPopup = self.childNode(withName: "exitPopup"), exitPopup.isHidden == false {
            if event.keyCode == 53 { // Escape
                self.childNode(withName: "stayMission")?.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                    SKAction.run { exitPopup.removeFromParent(); self.isGamePaused = false }
                ]))
                return
            }
        }
        switch event.keyCode {
        case 123: moveDirection.dx = -1
        case 124: moveDirection.dx = 1
        case 125: moveDirection.dy = -1
        case 126: moveDirection.dy = 1
        case 53: showExitPopup(); return
        default: break
        }
    }
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 123: if moveDirection.dx == -1 { moveDirection.dx = 0 }
        case 124: if moveDirection.dx == 1 { moveDirection.dx = 0 }
        case 125: if moveDirection.dy == -1 { moveDirection.dy = 0 }
        case 126: if moveDirection.dy == 1 { moveDirection.dy = 0 }
        case 49: shootBullets() // Space bar
        case 8: shootRocket() // C key
        default: break
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "leaveMission" {
                if let view = self.view {
                    let menuScene = MainMenuScene(size: CGSize(width: 1024, height: 640))
                    menuScene.scaleMode = .aspectFill
                    view.presentScene(menuScene, transition: SKTransition.fade(withDuration: 1.0))
                }
            } else if node.name == "stayMission" {
                self.childNode(withName: "exitPopup")?.removeFromParent()
                isGamePaused = false
                print("Game resumed.")
            } else if node.name == "mainMenuButton" {
                if let view = self.view {
                    let menuScene = MainMenuScene(size: CGSize(width: 1024, height: 640))
                    menuScene.scaleMode = .aspectFill
                    view.presentScene(menuScene, transition: SKTransition.fade(withDuration: 1.0))
                }
            } else if node.name == "missionCompletedOKButton" {
                if let view = self.view {
                    let menuScene = MainMenuScene(size: CGSize(width: 1024, height: 640))
                    menuScene.scaleMode = .aspectFill
                    view.presentScene(menuScene, transition: SKTransition.fade(withDuration: 1.0))
                }
            }
        }
    }

    // --- Bonus sprite logic (keep in this file) ---
    func loadBonusSprites() {
        guard let bonusTexture = SKTexture(imageNamed: "bonus.png") as SKTexture? else { return }
        let textureSize = bonusTexture.size()
        let frameWidth = textureSize.width / CGFloat(bonusCols)
        let frameHeight = textureSize.height / CGFloat(bonusRows)
        bonusFrames = []
        for row in 0..<bonusRows {
            var rowFrames: [SKTexture] = []
            let framesInRow = bonusFramesPerRow[row]
            for col in 0..<framesInRow {
                let rect = CGRect(
                    x: CGFloat(col) * frameWidth / textureSize.width,
                    y: CGFloat(bonusRows - 1 - row) * frameHeight / textureSize.height,
                    width: frameWidth / textureSize.width,
                    height: frameHeight / textureSize.height
                )
                let frame = SKTexture(rect: rect, in: bonusTexture)
                rowFrames.append(frame)
            }
            bonusFrames.append(rowFrames)
        }
    }

    func setupHeartsDisplay() {
        // Remove old hearts if any
        for node in heartNodes { node.removeFromParent() }
        heartNodes.removeAll()

        // Use row 1 (index 1) for hearts, 4 frames
        let heartFrames = bonusFrames.count > 1 ? bonusFrames[1] : []
        let heartSize = CGSize(width: 36, height: 36)

        for i in 0..<playerLives {
            let heart = SKSpriteNode(texture: heartFrames.first)
            heart.size = heartSize
            heart.position = CGPoint(x: 50 + CGFloat(i) * (heartSize.width - 10), y: size.height - 100) // Reduced spacing between hearts
            heart.zPosition = 1001
            addChild(heart)

            if heartFrames.count > 1 {
                heart.run(SKAction.repeatForever(SKAction.animate(with: heartFrames, timePerFrame: 0.18)))
            }

            heartNodes.append(heart)
        }
    }
    
    // Health bar setup for player
    func setupPlayerHealthBar() {
        // Find the y position of the hearts (first heart)
        let heartY = heartNodes.first?.position.y ?? (size.height - 100)
        let barY = heartY - 30 // 100px lower than hearts
        let barX = 43 // Same as hearts (distance from left)
        let barZ = heartNodes.first?.zPosition ?? 1001
        let barBackground = SKSpriteNode(color: .darkGray, size: CGSize(width: 50, height: 6))
        barBackground.anchorPoint = CGPoint(x: 0, y: 0.5)
        barBackground.position = CGPoint(x: CGFloat(barX), y: CGFloat(barY))
        barBackground.zPosition = barZ+2 // Match playerHealthBar zPosition
        barBackground.alpha = 0.7 // Make sure it's visible under the health bar
        addChild(barBackground)
        // Set up the player health bar with the correct width based on current health (max 50px)
        let healthBarWidth = max(0, min(50, CGFloat(playerHealth) / 2))
        let darkGreen = SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        let darkYellow = SKColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0)
        let darkRed = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        var barColor = darkGreen
        if playerHealth > 60 {
            barColor = darkGreen
        } else if playerHealth > 30 {
            barColor = darkYellow
        } else {
            barColor = darkRed
        }
        playerHealthBar = SKSpriteNode(color: barColor, size: CGSize(width: healthBarWidth, height: 5))
        playerHealthBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        playerHealthBar.position = CGPoint(x: CGFloat(barX), y: CGFloat(barY))
        playerHealthBar.zPosition = barZ+3 // Ensure it's above the background
        addChild(playerHealthBar)
    }
    
    func checkPlayerBulletCollisions() {
        var bulletsToRemove: [SKSpriteNode] = []
        for bullet in children where bullet.name == "enemyBullet" {
            if let bulletNode = bullet as? SKSpriteNode {
                if bulletNode.parent != nil && player.parent != nil && bulletNode.frame.intersects(player.frame) {
                    bulletsToRemove.append(bulletNode);
                    // Determine bullet type by image name
                    let imageName = bulletNode.texture?.description ?? ""
                    var damage = 20 // default bullet
                    if imageName.contains("RedRocket") { damage = 50 }
                    if imageName.contains("BigBomb") { damage = 80 }
                    if (damage > 0 && playerHealth > 0) {
                        let sound = SKAction.playSoundFileNamed("failure-02.mp3", waitForCompletion: false)
                        run(sound)
                    }
                    playerHealth -= damage
                    updatePlayerHealthBar()
                    if playerHealth <= 0 {
                        playerLives -= 1
                        showPlayerExplosion(at: player.position)
                        setupHeartsDisplay()
                        playerHealth = 100 // reset health for next life
                        if playerLives <= 0 {
                            removeAllActions()
                            let sound = SKAction.playSoundFileNamed("game-over-02.mp3", waitForCompletion: true)
                            run(sound)
                            showGameOverDialog()
                        }
                    
                        // Play hit sound
                        let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
                        run(sound)
                        
                        // Show "Life Lost!" text in the middle of the screen
                        let lifeTextNode = HelperFunctions.writeTextWithSprites("Life Lost!", charSize: CGSize(width: 36, height: 36), spacing: 4)
                        lifeTextNode.position = CGPoint(x: size.width/2 - lifeTextNode.calculateAccumulatedFrame().width/2, y: size.height/2)
                        lifeTextNode.zPosition = 2002
                        lifeTextNode.name = "lifeLostText"
                        addChild(lifeTextNode)
                        
                        // Remove after 1.5 seconds
                        lifeTextNode.run(SKAction.sequence([
                            SKAction.wait(forDuration: 1.5),
                            SKAction.fadeOut(withDuration: 0.5),
                            SKAction.removeFromParent()
                        ]))
                    }
                    break
                }
            }
        }
        for bullet in bulletsToRemove { bullet.removeFromParent() }
    }
    
    func updatePlayerHealthBar() {
        let healthBarWidth = max(0, min(50, CGFloat(playerHealth) / 2))
        let darkGreen = SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        let darkYellow = SKColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0)
        let darkRed = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        if playerHealth > 60 {
            playerHealthBar.color = darkGreen
        } else if playerHealth > 30 {
            playerHealthBar.color = darkYellow
        } else {
            playerHealthBar.color = darkRed
        }
        playerHealthBar.size.width = healthBarWidth
    }
    
    func checkPlayerEnemyCollisions() {
        for enemy in enemyPlanes {
            if player.frame.intersects(enemy.frame) {
                // Play explosion sound
                //let sound = SKAction.playSoundFileNamed("explosion_large.caf", waitForCompletion: false)
                //run(sound)
                let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
                run(sound)
                
                // Show "Life Lost!" text in the middle of the screen
                let missionStartNode = HelperFunctions.writeTextWithSprites("You lost a Life!", charSize: CGSize(width: 36, height: 36), spacing: 4)
                missionStartNode.position = CGPoint(x: size.width/2 - missionStartNode.calculateAccumulatedFrame().width/2, y: size.height/2)
                missionStartNode.zPosition = 2002
                missionStartNode.name = "missionStartText"
                addChild(missionStartNode)
                // Remove after 1 second
                missionStartNode.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.0),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.removeFromParent()
                ]))

                // Remove the enemy
                enemy.removeFromParent()
                if let index = enemyPlanes.firstIndex(of: enemy) {
                    enemyPlanes.remove(at: index)
                }
                showPlayerExplosion(at: player.position)
                // Reduce player lives
                playerLives -= 1
                setupHeartsDisplay()
                
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s in nanoseconds
                } // Wait for a moment before continuing

                // Check for game over
                if playerLives <= 0 {
                    removeAllActions()
                    let sound = SKAction.playSoundFileNamed("game-over-02.mp3", waitForCompletion: true)
                    run(sound)
                    showGameOverDialog()
                    return
                }
            }
        }
    }
    
    func playerDidLoseLife() {
        // Play sound
        let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
        self.run(sound)
        // Show "Life Lost!" text in the middle of the screen
        let textNode = HelperFunctions.writeTextWithSprites("Life Lost!", charSize: CGSize(width: 32, height: 32), spacing: 2)
        textNode.position = CGPoint(x: size.width/2 - (textNode.calculateAccumulatedFrame().width/2), y: size.height/2)
        textNode.zPosition = 2000
        addChild(textNode)
        // Remove after 1 second
        textNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
    
    func showPauseDialog() {
        let pauseOverlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.5), size: self.size)
        pauseOverlay.name = "pauseOverlay"
        pauseOverlay.zPosition = 1000
        addChild(pauseOverlay)

        let pauseLabel = SKLabelNode(fontNamed: "Courier-Bold")
        pauseLabel.text = "Game Paused"
        pauseLabel.fontSize = 40
        pauseLabel.fontColor = SKColor.white
        pauseLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        pauseLabel.zPosition = 1001
        pauseOverlay.addChild(pauseLabel)
    }

    func dismissPauseDialog() {
        self.childNode(withName: "pauseOverlay")?.removeFromParent()
    }
}
