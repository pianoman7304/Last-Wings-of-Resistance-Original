import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
// ...existing code...
    // --- Gameplay properties ---
    let scrollSpeed: CGFloat = 32
    var scrollOffset: CGFloat = 0
    var lastUpdateTime: TimeInterval = 0
    
    // landscape data
    let baseTileSize: CGFloat = 60
    var scaledTileWidth: CGFloat = 0.0
    var scaledTileHeight: CGFloat = 0.0
    var scaledTileSize: CGSize = .zero
    let mapWidth = 8 // Mission file coloumns
    let mapHeight = 75 // Mission file rows
    let visibleRows = 8
    var missionTileGrid: [[Character]] = []
    var tileImages: [SKTexture] = []
    var tileNodes: [[SKSpriteNode?]] = []
    var currentRow = 0
    var milesFlown = 0
    
    // Player properties
    var playerLives: Int = 3
    var maxPlayerLives: Int = 5
    var playerHealth: Int = 100
    let playerSpeed: CGFloat = 500
    var player: SKSpriteNode!
    var playerFrames: [SKTexture] = []
    var moveDirection: CGVector = .zero
    var bulletSpeed: CGFloat = 100 // later change to basebulletspeed * scaleFactor. works for player and enemies
    let baseBulletSpeed: CGFloat = 150
    var bullets: [SKNode] = []
    var enemyBombDuration: TimeInterval = 6.0 // Bomb speed configuration (higher duration = slower bomb)
    
    // Score and mission tracking
    var score: Int = 0
    var priorMissionsScore: Int = 0  // Total score across all missions
    var scoreLabel: SKLabelNode!
    
    // Info Display Mission
    var heartNodes: [SKSpriteNode] = []
    var bonusFrames: [[SKTexture]] = [] // [row][frame]
    var lastBonusSpawnTime: TimeInterval = 0
    let bonusRows = 13 // 13 bonus rows in the atlas
    let bonusCols = 6
    let bonusFramesPerRow = [6, 4, 6, 6, 6, 6, 4, 6, 6, 6, 6, 6, 6] // row 2 and 7 have 4 frames, others 6
    var playerHealthBar: SKSpriteNode!
    var customExitPopupNode: SKNode? = nil
    var exitPopupSelection: Int = 0 // 0 = Stay, 1 = Leave
    //var activeDialog: SKNode? = nil //iPad input dialog
    
    // game logic
    var lastRocketFireTime: TimeInterval = 0
    var nextBonusSpawnTime: TimeInterval = 0
    var activeBonus: SKSpriteNode?
    var bonusSpawnCount: Int = 0
    var backgroundMusicPlayer: AVAudioPlayer?
    var isGamePaused = false
    var currentMissionNumber: Int = 1
    var maxMissionNumber: Int = 5  // Maximum mission number (adjust based on your mission files)
    
    // --- Quad Shot Bonus ---
    var quadShotActive: Bool = false
    var quadShotMilesStart = 0
    let quadShotMiles = 100
    
    // --- Dual Direction Shot Bonus ---
    var dualShotActive: Bool = false
    var dualShotTimeRemaining: TimeInterval = 0
    let dualShotDuration: TimeInterval = 30.0 // 30 seconds
    
    // enemy planes
    var enemyPlanes: [EnemyPlane] = []
    let enemyPlaneFilenames: [String] = [
        "00139.png", "00140.png", "00250.png", "00260.png", "00270.png", "00280.png", "00290.png", "00300.png", "00310.png", "00320.png", "00330.png", "00340.png", "00350.png", "00355.png", "00360.png", "00410.png", "00450.png", "00500.png"
    ]
    var spawnedMissionPlanes: Set<Int> = []
    var enemyPlaneTextures: [SKTexture] = []
    let maxEnemies = 1
    let enemySpeed: CGFloat = 64
    let enemyHorizontalSpeed: CGFloat = 32
    var lastEnemySpawnTime: TimeInterval = 0
    var nextEnemySpawnDelay: Double = 0
    var missionPlanes: [(plane: String, x: Int, y: Int)] = []
    var killsPerEnemyType: [String: Int] = [:]
    let enemyTypeConfig: [String: (health: Int, moveSpeed: CGFloat, pattern: EnemyPlane.MovementPattern, canShoot: Bool, name: String, shotType: String, shotsAtOnce: Int, shootFrequency: Double)] = [
        "00139.png": (health: 5, moveSpeed: 80.0, pattern: .sine, canShoot: true, name: "OrangeStorm", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 3.0),
        "00140.png": (health: 5, moveSpeed: 80.0, pattern: .straight, canShoot: true, name: "NavyBlue", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 3.0),
        "00250.png": (health: 2, moveSpeed: 56.0, pattern: .zigzag, canShoot: true, name: "JumpingFrog", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 3.0),
        "00260.png": (health: 4, moveSpeed: 40.0, pattern: .straight, canShoot: true, name: "FireBall", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 3.0),
        "00270.png": (health: 2, moveSpeed: 48.0, pattern: .zigzag, canShoot: true, name: "LemonTree", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 3.0),
        "00280.png": (health: 2, moveSpeed: 120.0, pattern: .sine, canShoot: true, name: "YellowStar", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 3.0),
        "00290.png": (health: 8, moveSpeed: 120.0, pattern: .zigzag, canShoot: true, name: "BlackArrow", shotType: "rocket", shotsAtOnce: 2, shootFrequency: 3.0),
        "00300.png": (health: 5, moveSpeed: 96.0, pattern: .straight, canShoot: true, name: "DarkFire", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 3.0),
        "00310.png": (health: 4, moveSpeed: 40.0, pattern: .sine, canShoot: true, name: "SteelEye", shotType: "bomb", shotsAtOnce: 2, shootFrequency: 3.0),
        "00320.png": (health: 1, moveSpeed: 48.0, pattern: .random, canShoot: false, name: "Butterfly", shotType: "-", shotsAtOnce: 1, shootFrequency: 3.0),
        "00330.png": (health: 10, moveSpeed: 144.0, pattern: .straight, canShoot: true, name: "BoolShid", shotType: "bullet", shotsAtOnce: 4, shootFrequency: 3.0),
        "00340.png": (health: 2, moveSpeed: 64.0, pattern: .straight, canShoot: true, name: "MilitaryStep", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 3.0),
        "00350.png": (health: 3, moveSpeed: 40.0, pattern: .sine, canShoot: false, name: "DesertFox", shotType: "-", shotsAtOnce: 1, shootFrequency: 3.0),
        "00355.png": (health: 2, moveSpeed: 60.0, pattern: .random, canShoot: true, name: "Cigarillo", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 3.0),
        "00360.png": (health: 2, moveSpeed: 72.0, pattern: .zigzag, canShoot: true, name: "LimboDance", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 3.0),
        "00410.png": (health: 50, moveSpeed: 24.0, pattern: .straight, canShoot: false, name: "CloudFrank", shotType: "-", shotsAtOnce: 2, shootFrequency: 3.0),
        "00450.png": (health: 1, moveSpeed: 24.0, pattern: .sine, canShoot: false, name: "Walti", shotType: "-", shotsAtOnce: 1, shootFrequency: 3.0),
        "00500.png": (health: 1, moveSpeed: 56.0, pattern: .random, canShoot: true, name: "Baby", shotType: "bomb", shotsAtOnce: 1, shootFrequency: 3.0)
    ]
    
    override func didMove(to view: SKView) {
        // Set up the scene size and background color
        HelperFunctions.scaleFactor = size.width / (CGFloat(mapWidth) * baseTileSize)
        scaledTileWidth = baseTileSize * HelperFunctions.scaleFactor
        scaledTileHeight = baseTileSize * HelperFunctions.scaleFactor
        scaledTileSize = CGSize(width: scaledTileWidth, height: scaledTileHeight)
        // Initialize tileNodes with nil
        loadMissionFile()
        loadTileAtlas()
        setupMissionTiles()
        killsPerEnemyType = [:]
        setupPlayer()
        setupScoreLabel()
        // Initialize en    emy textures
        bulletSpeed = baseBulletSpeed * HelperFunctions.scaleFactor
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
        //let screenWidth = size.width
        
        // Add game controller support for macOS and iOS and tvOS
        ControllerInputHandler.shared.registerGameScene(self)
        
        // Set up IPad input overlay for iOS
        #if os(iOS)
        let inputOverlay = iPadInputOverlay()
        inputOverlay.delegate = self
        inputOverlay.zPosition = 9999
        addChild(inputOverlay)
        inputOverlay.updateJoystickPosition()
        inputOverlay.updatePauseButtonPosition()
        #endif
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

        // Set maxMissionNumber based on the number of mission files found
        maxMissionNumber = missionNames.count
        print("Found \(maxMissionNumber) mission files: \(missionNames)")

        // Load the specific mission based on currentMissionNumber
        let missionFileName = String(format: "Mission %02d", currentMissionNumber)
        let selectedMission = missionNames.first { $0 == missionFileName } ?? "Mission 01"
        print("Loading mission: \(selectedMission) for mission number: \(currentMissionNumber)")
        
        let missionPath = Bundle.main.path(forResource: selectedMission, ofType: "txt")
        
       // for testing - hardcoded mission number
        // let missionPath = Bundle.main.path(forResource: "Mission 05", ofType: "txt")
        
        guard let path = missionPath, let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            showMissionFileErrorDialog()
            missionTileGrid = Array(repeating: Array(repeating: "A", count: mapWidth), count: mapHeight)
            return
        }
        // Check for correct length (8x75 = 600) for landscape data then planes data
        if text.count < 600 {
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
        loadMissionPlanes(from: text)
    }
    
    // Loads the tile atlas and cuts it into 16 tiles (4x4), flipping y-axis to match editor
    func loadTileAtlas() {
        let atlasTexture = SKTexture(imageNamed: "Landscape-Atlas-01.png")
        tileImages = []
        let tileCols = 4
        let tileRows = 7

        let atlasSize = atlasTexture.size()
        let subTileWidth = atlasSize.width / CGFloat(tileCols)
        let subTileHeight = atlasSize.height / CGFloat(tileRows)
        for y in 0..<tileRows {
            let flippedY = tileRows - 1 - y
            for x in 0..<tileCols {
                let rect = CGRect(
                    x: CGFloat(x) * subTileWidth / atlasSize.width,
                    y: CGFloat(flippedY) * subTileHeight / atlasSize.height,
                    width: subTileWidth / atlasSize.width,
                    height: subTileHeight / atlasSize.height
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
        //let scaledTileWidth = baseTileSize * HelperFunctions.scaleFactor
        //let scaledTileHeight = baseTileSize * HelperFunctions.scaleFactor
        //let scaledTileSize = CGSize(width: scaledTileWidth, height: scaledTileHeight)
        for row in 0..<visibleRows {
            for col in 0..<mapWidth {
                let tileChar = missionTileGrid[row][col]
                let tileIdx = tileIndex(for: tileChar)
                let tileTexture = tileIdx < tileImages.count ? tileImages[tileIdx] : nil
                let node = SKSpriteNode(texture: tileTexture)
                node.size = scaledTileSize
                node.anchorPoint = CGPoint(x: 0, y: 0)
                node.position = CGPoint(x: CGFloat(col) * scaledTileSize.width, y: CGFloat(row) * scaledTileSize.height)
                node.zPosition = -10
                addChild(node)
                tileNodes[row][col] = node
            }
        }
    }
    
    // Helper to map tile char (A-P) to index
    func tileIndex(for char: Character) -> Int {
        if let ascii = char.asciiValue {
            if ascii >= 65 && ascii <= 90 { // 'A'-'Z'
                return Int(ascii - 65)
            } else if ascii == 97 { // 'a'
                return 26
            } else if ascii == 98 { // 'b'
                return 27
            }
        }
        return 0 // default/fallback
    }
    
    // Updates the visible tiles based on scrollOffset, scaling to full screen width (no y-flip)
    func updateVisibleMissionTiles() {
        let screenWidth = size.width
        //let scaledTileWidth = baseTileSize * HelperFunctions.scaleFactor
        //let scaledTileHeight = baseTileSize * HelperFunctions.scaleFactor
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
        playerFrames = frameNames.compactMap { SKTexture(imageNamed: $0) }
        if playerFrames.isEmpty {
            print("Player sprite frames not found! Check that me-01-an01.png etc. are in the bundle.")
            player = SKSpriteNode(color: .red, size: CGSize(width: scaledTileWidth / 60 * 32, height: scaledTileHeight / 60 * 32))
        } else {
            player = SKSpriteNode(texture: playerFrames.first)
            player.size = CGSize(width: scaledTileWidth / 60 * 32, height: scaledTileHeight / 60 * 32)
            player.position = CGPoint(x: size.width/2, y: scaledTileHeight * 2)
            addChild(player)
            player.run(SKAction.repeatForever(SKAction.animate(with: playerFrames, timePerFrame: 0.1)))
        }
    }
    
   
    
    
    // --- Enemy plane logic ---
    func loadMissionPlanes(from text: String) {
        // Ensure the text is long enough to contain landscape data.
        print(text.count)
        guard text.count > 600 else {
            print("Mission file text is too short to contain plane data.")
            return
        }
        
        // Get the part of the string after the landscape data.
        let planeDataString = text.dropFirst(600)
        
        // Split into lines, removing any empty lines.
        let lines = planeDataString.split(separator: "\n")
        
        // Use compactMap to parse each line and filter out invalid entries.
        missionPlanes = lines.compactMap { line -> (plane: String, x: Int, y: Int)? in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { return nil }
            
            let parts = trimmedLine.split(separator: "-")
            guard parts.count == 2 else {
                print("Invalid plane data line: \(line)")
                return nil
            }
            let planeType = String(parts[0])
            let coords = parts[1].split(separator: ",")
            guard coords.count == 2,
                  let x = Int(coords[0]),
                  let y = Int(coords[1]) else {
                print("Invalid plane coordinates: \(line)")
                return nil
            }
            return (plane: planeType, x: x, y: y)
        }
        print("Loaded \(missionPlanes.count) mission planes")
        // Debug output
        /*
         for (plane, x, y) in missionPlanes {
            print("Plane: \(plane), X: \(x), Y: \(y)")
        }
         */
    }


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
                            let planeType = enemy.name ?? "Unknown"
                            killsPerEnemyType[planeType, default: 0] += 1
                            print("[GameScene] Kill tracked: \(planeType), total kills: \(killsPerEnemyType)")
                            explodeEnemy(enemy)
                            if let idx = enemyPlanes.firstIndex(of: enemy) { enemyPlanes.remove(at: idx) }
                        }
                        break
                    }
                } else if bullet.name == "bullet" || bullet.name == "playerBullet" || bullet.name == "leftBullet" || bullet.name == "rightBullet" || bullet.name == "forwardBullet" || bullet.name == "backwardBullet" {
                        
                    if let bulletNode = bullet as? SKSpriteNode, bulletNode.frame.intersects(enemy.frame) {
                        // Bullet does 1 damage
                        enemy.health -= 1
                        bulletsToRemove.append(bulletNode)
                        if enemy.health <= 0 {
                            // Score calculation: health * moveSpeed / 10 * shotsAtOnce
                            let points = Int(round(Double(enemy.initialHealth) * Double(enemy.moveSpeed) / 10.0 * Double(enemy.shotsAtOnce)))
                            score += points
                            updateScoreLabel()
                            let planeType = enemy.name ?? "Unknown"
                            killsPerEnemyType[planeType, default: 0] += 1
                            print("[GameScene] Kill tracked: \(planeType), total kills: \(killsPerEnemyType)")
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
        nextBonusSpawnTime = currentTime + Double.random(in: 10.0...15.0)
    }
    
    // spwan verious bonuses
    func spawnRandomBonus() {
        guard activeBonus == nil else { return } // Only one bonus at a time
        bonusSpawnCount += 1

        // equal chance for dual shot, quad shot, addLife, fullHealth
        let bonusTypes = [(0, "quadShot"), (10, "dualShot"), (1, "addLife"), (12, "fullHealth")]
        let (bonusType, bonusName) = bonusTypes.randomElement()!
        
        /*
        // Every 7th bonus is quad shot, every 5th is addLife, otherwise fullHealth
        let isDualShot = bonusSpawnCount % 9 == 0
        let isQuadShot = !isDualShot && bonusSpawnCount % 7 == 0
        let isAddLife = !isDualShot && !isQuadShot && bonusSpawnCount % 5 == 0
         
         let bonusType: Int
         let bonusName: String
     
        // Determine bonus type and name based on conditions
        if isDualShot {
            bonusType = 10 // dual shot row
            bonusName = "dualShot"
        } else if isQuadShot {
            bonusType = 0 // quad shot row
            bonusName = "quadShot"
        } else if isAddLife {
            bonusType = 1 // addLife row
            bonusName = "addLife"
        } else {
            bonusType = 12 // fullHealth row
            bonusName = "fullHealth"
        }
         */

        let bonusFramesArr = (bonusFrames.count > bonusType) ? bonusFrames[bonusType] : []
        let frameCount = bonusFramesArr.count
        guard frameCount > 0 else { return }
        let bonus = SKSpriteNode(texture: bonusFramesArr.first)
        bonus.size = CGSize(width: scaledTileWidth / 60 * 32, height: scaledTileHeight / 60 * 32)
        let x = CGFloat.random(in: scaledTileWidth...(size.width-scaledTileWidth))
        let y = size.height + 40 * HelperFunctions.scaleFactor
        bonus.position = CGPoint(x: x, y: y)
        bonus.zPosition = 1200
        bonus.name = bonusName
        addChild(bonus)
        activeBonus = bonus
        // Animate
        let animate = SKAction.repeatForever(SKAction.animate(with: bonusFramesArr, timePerFrame: 0.15))
        bonus.run(animate)
        // Move down
        let moveDown = SKAction.moveTo(y: -60, duration: 6.0)
        let remove = SKAction.run { [weak self] in self?.activeBonus = nil; bonus.removeFromParent() }
        bonus.run(SKAction.sequence([moveDown, remove]))
        
        print("Spawning bonus: \(bonusName), using row \(bonusType), frames: \(bonusFramesArr.count)")
    }
    
    func checkPlayerBonusCollisions() {
        guard let bonus = activeBonus else { return }
        if player.frame.intersects(bonus.frame) {
            if bonus.name == "addLife" {
                playerLives = min(playerLives + 1, maxPlayerLives)
                setupHeartsDisplay()
                let sound = SKAction.playSoundFileNamed("game-point-02.mp3", waitForCompletion: false)
                run(sound)
            } else if bonus.name == "fullHealth" {
                playerHealth = 100
                updatePlayerHealthBar()
                let sound = SKAction.playSoundFileNamed("game-point-01.mp3", waitForCompletion: false)
                run(sound)
            } else if bonus.name == "quadShot" {
                quadShotActive = true
                quadShotMilesStart = milesFlown
                let sound = SKAction.playSoundFileNamed("game-point-03.mp3", waitForCompletion: false)
                run(sound)
            } else if bonus.name == "dualShot" {
                dualShotActive = true
                dualShotTimeRemaining = dualShotDuration
                let sound = SKAction.playSoundFileNamed("game-point-04.mp3", waitForCompletion: false)
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
        scrollOffset += scrollSpeed * CGFloat(dt) * HelperFunctions.scaleFactor / 2 // Adjust speed for scaling
        let maxOffset = CGFloat(mapHeight - visibleRows) * baseTileSize * HelperFunctions.scaleFactor
        if scrollOffset > maxOffset {
            scrollOffset = maxOffset
        }
        updateVisibleMissionTiles()
        // Show mission completed dialog if at end
        if scrollOffset >= maxOffset && self.childNode(withName: "missionCompletedPopup") == nil {
            showMissionCompletedDialog()
            // Transition to MissionEndScene after a delay
            if let view = self.view {
                HelperFunctions.transitionToMissionEndScene(
                    from: view,
                    currentMissionNumber: currentMissionNumber,
                    killsPerEnemyType: killsPerEnemyType,
                    score: score,
                    priorMissionsScore: priorMissionsScore,
                    maxMissionNumber: maxMissionNumber,
                    playerDied: false
                )
                
            }
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
            let maxY = baseTileSize * CGFloat(visibleRows) * HelperFunctions.scaleFactor - player.size.height / 2
            newPosition.x = max(minX, min(newPosition.x, maxX))
            newPosition.y = max(minY, min(newPosition.y, maxY))
            player.position = newPosition
        }
        
        updateMilesFlownLabel()
        updateMissionNumberLabel()
        
        // --- Enemy and bullet update logic ---
        updateEnemyPlanesSmart(CGFloat(dt), currentTime: currentTime)
        checkBulletEnemyCollisionsSmart()
        checkPlayerEnemyCollisions()
        checkPlayerBulletCollisions()

        // --- Mission plane spawning logic ---
        // For each plane in missionPlanes, check if it should be spawned
        
        //print("scrollOffset:", scrollOffset, ", visibleMaxY:", scrollOffset + CGFloat(visibleRows) * baseTileSize * scaleFactor, ", scaledTileHeight:", scaledTileHeight, ", visibleRows:", visibleRows, ", mapHeight:", mapHeight, ", scaleFactor:", scaleFactor)
       
        for (index, plane) in missionPlanes.enumerated() {
            let planeKey = "\(plane.plane)-\(plane.x),\(plane.y)"
            // Calculate invertedY based on map height and mission file y coordinate
            let invertedY = (CGFloat(mapHeight) * baseTileSize - CGFloat(plane.y)) * HelperFunctions.scaleFactor
            
            let visibleMinY = scrollOffset
            let visibleMaxY = scrollOffset + size.height + HelperFunctions.scaleFactor * 32 //+ CGFloat(visibleRows) * baseTileSize * HelperFunctions.scaleFactor
           
            if invertedY >= visibleMinY && invertedY < visibleMaxY && !spawnedMissionPlanes.contains(planeKey.hashValue) {
                //print("Checking plane (in if) \(index): \(plane.plane) at X: \(plane.x), Y: \(plane.y) (invertedY: \(invertedY)), visible range: \(visibleMinY) to \(visibleMaxY), HelperFunctions.scaleFactor: \(HelperFunctions.scaleFactor)")
                
                // Find the correct texture for the plane type
                let planeTextureName = plane.plane + ".png"
                let planeTexture = SKTexture(imageNamed: planeTextureName)
                // Get enemy config for this type
                let config = enemyTypeConfig[planeTextureName] ?? (health: 3, moveSpeed: 64.0, pattern: EnemyPlane.MovementPattern.straight, canShoot: false, name: "Unknown", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 3.0)
                // Create the enemy plane node = EnemyPlane(using the full initializer to set movement and shooting properties
                let enemy = EnemyPlane(
                    texture: planeTexture,
                    health: config.health,
                    speed: config.moveSpeed,
                    pattern: config.pattern,
                    canShoot: config.canShoot,
                    shotType: config.shotType,
                    shotsAtOnce: config.shotsAtOnce,
                    shootFrequency: config.shootFrequency,
                    gameScene: self
                )
                enemy.name = planeTextureName  // Store the plane type for kill tracking
                enemy.size = CGSize(width: HelperFunctions.scaleFactor * 32, height: HelperFunctions.scaleFactor * 32)
                enemy.position = CGPoint(x: CGFloat(plane.x) * HelperFunctions.scaleFactor, y: size.height + HelperFunctions.scaleFactor * 32)   //y: invertedY * 1
                
                enemy.zPosition = 20
                addChild(enemy)
                enemyPlanes.append(enemy)
                spawnedMissionPlanes.insert(planeKey.hashValue)
            }
        }
        // --- Random spawn logic (unchanged) ---
        if enemyPlanes.isEmpty {
            if nextEnemySpawnDelay <= 0 {
                nextEnemySpawnDelay = Double.random(in: 1.0...10.0)
                lastEnemySpawnTime = currentTime
            } else if currentTime - lastEnemySpawnTime > nextEnemySpawnDelay {
                spawnEnemyPlanesSmart()
                nextEnemySpawnDelay = 0
            }
        }
        // quad shot bonus logic
        if quadShotActive {
            
            if ((quadShotMiles + quadShotMilesStart) < milesFlown) {
                quadShotActive = false
            }
        }
        if dualShotActive {
            dualShotTimeRemaining -= dt
            if dualShotTimeRemaining <= 0 {
                dualShotActive = false
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
        let bulletImage = "FastBullet3.png"
        let bulletScale: CGFloat = 1.0
        let bulletSpeed: CGFloat = self.bulletSpeed

        let bulletYOffset: CGFloat = player.size.height / 2
        let bulletXOffset: CGFloat = player.size.width * 0.22

        let moveDistance = scaledTileHeight * CGFloat(visibleRows) + 200 // Move up beyond visible area
        let moveDuration = Double(moveDistance) / Double(bulletSpeed)
        let moveActionForward = SKAction.moveBy(x: 0, y: moveDistance, duration: moveDuration)
        let moveActionBackward = SKAction.moveBy(x: 0, y: -moveDistance, duration: moveDuration)
        let removeAction = SKAction.removeFromParent()

        // --- Always shoot 2 forward bullets ---
        let forwardOffsets: [CGFloat]
        if quadShotActive {
            // 4 bullets: 2 left, 2 right, same y
            forwardOffsets = [
                -bulletXOffset * 1.5,
                -bulletXOffset * 0.5,
                bulletXOffset * 0.5,
                bulletXOffset * 1.5
            ]
        } else {
            // Standard 2-bullet shot
            forwardOffsets = [
                -bulletXOffset,
                bulletXOffset
            ]
        }
        for xOffset in forwardOffsets {
            let bullet = SKSpriteNode(imageNamed: bulletImage)
            bullet.setScale(bulletScale)
            bullet.position = CGPoint(x: player.position.x + xOffset, y: player.position.y + bulletYOffset)
            bullet.zPosition = 10
            bullet.size = CGSize(width: HelperFunctions.scaleFactor * 13/2, height: HelperFunctions.scaleFactor * 13/2)
            bullet.name = "forwardBullet"
            addChild(bullet)
            bullet.run(SKAction.sequence([moveActionForward, removeAction]))
        }

        // --- If dualShotActive, shoot 2 backward bullets ---
        if dualShotActive {
            let backwardOffsets: [CGFloat] = [
                -bulletXOffset,
                bulletXOffset
            ]
            for xOffset in backwardOffsets {
                let bullet = SKSpriteNode(imageNamed: bulletImage)
                bullet.setScale(bulletScale)
                bullet.position = CGPoint(x: player.position.x + xOffset, y: player.position.y - bulletYOffset)
                bullet.zPosition = 10
                bullet.size = CGSize(width: HelperFunctions.scaleFactor * 13/2, height: HelperFunctions.scaleFactor * 13/2)
                bullet.name = "backwardBullet"
                addChild(bullet)
                bullet.run(SKAction.sequence([moveActionBackward, removeAction]))
            }
        }

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
        rocket.size = CGSize(width: HelperFunctions.scaleFactor * 10/2, height: HelperFunctions.scaleFactor * 16/2)
        rocket.name = "playerRocket"
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: scaledTileHeight * CGFloat(visibleRows) + rocket.size.height), duration: 2.0) // Move up beyond visible area
        let removeAction = SKAction.removeFromParent()
        rocket.run(SKAction.sequence([moveAction, removeAction]))
        addChild(rocket)
        let sound = SKAction.playSoundFileNamed("laser_ship.caf", waitForCompletion: false)
        run(sound)
    }
    
    // Game controller input handling - all OS
    
    func movePlayerWithController(dx: CGFloat, dy: CGFloat) {
        // If the joystick is moved, set the direction (-1, 0, or 1 for each axis)
        if abs(dx) > 0.2 {
            moveDirection.dx = dx > 0 ? 1 : -1
        } else {
            moveDirection.dx = 0
        }
        if abs(dy) > 0.2 {
            moveDirection.dy = dy > 0 ? 1 : -1
        } else {
            moveDirection.dy = 0
        }
    }
    
    // MacOS key handling
    
    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        // Custom Exit Popup handling
        
        //print("keyDown: customExitPopupNode is", customExitPopupNode)
        
        if let popup = customExitPopupNode {
            let options = (popup.userData?["options"] as? [String]) ?? []
            
            if options.count > 1 { // For dialogs with multiple options like "Stay/Leave"
                switch event.keyCode {
                case 123, 124: // Left, Right
                    exitPopupSelection = 1 - exitPopupSelection
                    updateCustomExitPopupSelection()
                case 36, 49: // Return, Space
                    if exitPopupSelection == 0 { // Stay
                        removeCustomExitPopup()
                    } else { // Leaveself.view?.window?.makeFirstResponder(self)
                        if let view = self.view {
                            HelperFunctions.transitionToMainMenuScene(from: view)
                        }
                    }
                case 53: // Escape
                    removeCustomExitPopup() // Always treat as "Stay"
                default: break
                }
            } else { // For single-option dialogs like "OK"
                switch event.keyCode {
                case 36, 49: // Return, Space
                    // Find the action associated with the OK button
                    if popup.name == "gameOverPopup" || popup.name == "missionCompletedPopup" {
                        if let view = self.view {
                        HelperFunctions.transitionToMissionEndScene(
                            from: view,
                            currentMissionNumber: currentMissionNumber,
                            killsPerEnemyType: killsPerEnemyType,
                            score: score,
                            priorMissionsScore: priorMissionsScore,
                            maxMissionNumber: maxMissionNumber,
                            playerDied: (popup.name == "gameOverPopup") )
                        }
                        
                    } else { // missionFileErrorPopup
                        removeCustomExitPopup()
                    }
                default: break
                }
            }
            return // Stop further key processing
        }
        
        // Normal game key handling
        switch event.keyCode {
        case 123: moveDirection.dx = -1
        case 124: moveDirection.dx = 1
        case 125: moveDirection.dy = -1
        case 126: moveDirection.dy = 1
        case 53: showCustomExitPopup(); return
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
        case 35: // "P" key - simluate mission completion - to be removed after for game publishing
            if let view = self.view {
                // Transition to MissionEndScene with simulated mission completion
                HelperFunctions.transitionToMissionEndScene(
                    from: view,
                    currentMissionNumber: currentMissionNumber,
                    killsPerEnemyType: killsPerEnemyType,
                    score: score,
                    priorMissionsScore: priorMissionsScore,
                    maxMissionNumber: maxMissionNumber,
                    playerDied: false
                )
            }
            return
        default: break
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "leaveMission" {
                if let view = self.view {
                    HelperFunctions.transitionToMainMenuScene(from: view)
                    
                }
            } else if node.name == "stayMission" {
                self.childNode(withName: "exitPopup")?.removeFromParent()
                isGamePaused = false
                print("Game resumed.")
            } else if node.name == "mainMenuButton" {
                if let view = self.view {
                    HelperFunctions.transitionToMainMenuScene(from: view)
                    
                }
            } else if node.name == "missionCompletedOKButton" {
                if let view = self.view {
                    HelperFunctions.transitionToMainMenuScene(from: view)
                    
                }
            }
        }
    }
    #endif
    
    // input handling for flying the plane on iOS
    
    #if os(iOS)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Handle any active dialog (OK, Stay/Leave, error, etc.)
        if let popup = customExitPopupNode {
            if let optionsNode = popup.childNode(withName: "optionsNode") {
                // Convert touch location to optionsNode's coordinate space
                let localLocation = optionsNode.convert(location, from: self)
                for case let sprite as SKSpriteNode in optionsNode.children {
                    if sprite.contains(localLocation) {
                        if let options = popup.userData?["options"] as? [String], options.count == 1 {
                            // Single-option dialog (e.g. OK, error)
                            if popup.name == "gameOverPopup" || popup.name == "missionCompletedPopup" {
                                if let view = self.view {
                                    HelperFunctions.transitionToMissionEndScene(
                                        from: view,
                                        currentMissionNumber: currentMissionNumber,
                                        killsPerEnemyType: killsPerEnemyType,
                                        score: score,
                                        priorMissionsScore: priorMissionsScore,
                                        maxMissionNumber: maxMissionNumber,
                                        playerDied: (popup.name == "gameOverPopup")
                                    )
                                }
                            } else {
                                // Handles missionFileErrorPopup and other single-option dialogs
                                removeCustomExitPopup()
                            }
                            return
                        } else if let options = popup.userData?["options"] as? [String], options.count > 1 {
                            // Multi-option dialog (e.g. Stay/Leave)
                            let sprites = optionsNode.children.compactMap { $0 as? SKSpriteNode }
                            for (i, sprite) in sprites.enumerated() {
                                if sprite.contains(localLocation) {
                                    exitPopupSelection = (i < sprites.count / 2) ? 0 : 1
                                    updateCustomExitPopupSelection()
                                    if exitPopupSelection == 0 {
                                        removeCustomExitPopup()
                                    } else {
                                        if let view = self.view {
                                            HelperFunctions.transitionToMainMenuScene(from: view)
                                        }
                                    }
                                    return
                                }
                            }
                        }
                        return
                    }
                }
            }
            // Always consume the touch if dialog is active
            return
        }
        // ...other touch handling (e.g., gameplay)...
    }

    
    func didUpdateMoveDirection(_ direction: CGVector) {
        // Set your movement direction variable, e.g.:
        moveDirection = direction
    }

    func didPressFire1() {
        // Call your bullet firing logic, e.g.:
        shootBullets()
    }

    func didPressFire2() {
        // Call your rocket firing logic, e.g.:
        shootRocket()
    }
        
    #endif
    
    
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
        
        // debug
        /*
         print("Loaded bonusFrames:")
        for (i, row) in bonusFrames.enumerated() {
            print("Row \(i): \(row.count) frames")
        }
         */
        
    }
    
    func setupHeartsDisplay() {
        for node in heartNodes { node.removeFromParent() }
        heartNodes.removeAll()
        let heartFrames = bonusFrames.count > 1 ? bonusFrames[1] : []
        let heartSize = CGSize(width: scaledTileWidth / 2.5, height: scaledTileHeight / 2.5)
        for i in 0..<playerLives {
            let heart = SKSpriteNode(texture: heartFrames.first)
            heart.size = heartSize
            heart.position = CGPoint(x: 30 * HelperFunctions.scaleFactor + CGFloat(i) * (heartSize.width - 10 * HelperFunctions.scaleFactor), y: size.height - 50 * HelperFunctions.scaleFactor)
            heart.zPosition = 1001
            addChild(heart)
            if heartFrames.count > 1 {
                heart.run(SKAction.repeatForever(SKAction.animate(with: heartFrames, timePerFrame: 0.18)))
            }
            heartNodes.append(heart)
        }
        
        let heartY: CGFloat
        let barZ: CGFloat
        if let firstHeart = heartNodes.first {
            heartY = firstHeart.position.y
            barZ = firstHeart.zPosition
        } else {
            heartY = size.height - 50 * HelperFunctions.scaleFactor
            barZ = 1001
        }
    }
    
    // Health bar setup for player
    func setupPlayerHealthBar() {
        // Remove old health bar/background if any
        playerHealthBar?.removeFromParent()
        let oldBackground = self.childNode(withName: "playerHealthBarBackground")
        oldBackground?.removeFromParent()

        // Get heart position and zPosition, or use defaults
        let heartY: CGFloat
        let barZ: CGFloat
        let barX: CGFloat
        if let firstHeart = heartNodes.first {
            heartY = firstHeart.position.y
            barZ = firstHeart.zPosition
            barX = firstHeart.position.x - 5  * HelperFunctions.scaleFactor
        } else {
            heartY = size.height - 60 * HelperFunctions.scaleFactor
            barZ = 1001
            barX = 43 * HelperFunctions.scaleFactor
        }

        // Offset the health bar below the hearts
        let barY = heartY + scaledTileHeight / 2 - (15 * HelperFunctions.scaleFactor)  // Move down by 20 pixels scaled

        // Set the width and height for both background and front bar
        let barWidth = scaledTileWidth / 60 * 50
        let barHeight = scaledTileHeight / 60 * 6

        // Create and add the background bar
        let barBackground = SKSpriteNode(color: .darkGray, size: CGSize(width: barWidth, height: barHeight))
        barBackground.anchorPoint = CGPoint(x: 0, y: 0.5)
        barBackground.position = CGPoint(x: barX, y: barY)
        barBackground.zPosition = barZ + 2
        barBackground.alpha = 0.7
        barBackground.name = "playerHealthBarBackground"
        addChild(barBackground)

        // Calculate health bar width as a proportion of barWidth
        let healthBarWidth = max(0, min(barWidth, barWidth * CGFloat(playerHealth) / 100))
        let barColor: SKColor
        if playerHealth > 60 {
            barColor = SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0) // dark green
        } else if playerHealth > 30 {
            barColor = SKColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0) // dark yellow
        } else {
            barColor = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0) // dark red
        }

        // Create and add the front health bar
        playerHealthBar = SKSpriteNode(color: barColor, size: CGSize(width: healthBarWidth, height: barHeight - 1))
        playerHealthBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        playerHealthBar.position = CGPoint(x: barX, y: barY)
        playerHealthBar.zPosition = barZ + 3
        addChild(playerHealthBar)
    }
    
    func updatePlayerHealthBar() {
        // Ensure the health bar exists
        guard let playerHealthBar = playerHealthBar else { return }

        // Use the same barWidth as in setupPlayerHealthBar
        let barWidth = scaledTileWidth / 60 * 50

        // Calculate health bar width as a proportion of barWidth
        let healthBarWidth = max(0, min(barWidth, barWidth * CGFloat(playerHealth) / 100))

        // Update color based on health
        let barColor: SKColor
        if playerHealth > 60 {
            barColor = SKColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0) // dark green
        } else if playerHealth > 30 {
            barColor = SKColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0) // dark yellow
        } else {
            barColor = SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0) // dark red
        }

        // Update health bar properties
        playerHealthBar.color = barColor
        playerHealthBar.size.width = healthBarWidth
    }
    
    /*
    func playerDidLoseLife() {
        // Play sound
        let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
        self.run(sound)
        // Show "Life Lost!" text in the middle of the screen
        playerDidLoseLifeWrite()
        // Reduce player lives and reset health
        playerLives -= 1
        setupHeartsDisplay()
        playerHealth = 100
        updatePlayerHealthBar()
        quadShotActive = false // Reset quad shot bonus
        // Check for game over
        if playerLives <= 0 {
            removeAllActions()
            let gameOverSound = SKAction.playSoundFileNamed("game-over-02.mp3", waitForCompletion: true)
            run(gameOverSound)
            showGameOverDialog()
        }
    }
     */
    
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
                        updatePlayerHealthBar()
                        if playerLives <= 0 {
                            removeAllActions()
                            let sound = SKAction.playSoundFileNamed("game-over-02.mp3", waitForCompletion: true)
                            run(sound)
                            showGameOverDialog()
                        }
                        else
                        {
                            // Play hit sound
                            let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
                            run(sound)
                            
                            // Show "Life Lost!" text in the middle of the screen
                            playerDidLoseLifeWrite()
                        }
                    }
                    break
                }
            }
        }
        for bullet in bulletsToRemove { bullet.removeFromParent() }
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
                playerDidLoseLifeWrite()
                
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
    
    func playerDidLoseLifeWrite() {
        // Play sound
        let sound = SKAction.playSoundFileNamed("failure-03.mp3", waitForCompletion: false)
        self.run(sound)
        // Show "Life Lost!" text in the middle of the screen
        let textNode = HelperFunctions.writeTextWithSprites("You lost a Life!", charSize: CGSize(width: 28, height: 28), spacing: 2)
        textNode.position = CGPoint(x: size.width/2 - (textNode.calculateAccumulatedFrame().width/2), y: size.height/2 + 20 * HelperFunctions.scaleFactor)
        textNode.zPosition = 2000
        addChild(textNode)
        // Remove after 1 second
        textNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
}


#if os(iOS)

extension GameScene: iPadInputDelegateWithPause {
    func didPressPause() {
        showCustomExitPopup()
    }
}

#endif
