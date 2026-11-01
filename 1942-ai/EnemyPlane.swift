import SpriteKit

// Configuration for enemy types by sprite filename
let enemyTypeConfig: [String: (health: Int, moveSpeed: CGFloat, pattern: EnemyPlane.MovementPattern, canShoot: Bool, name: String, shotType: String, shotsAtOnce: Int, shootFrequency: Double)] = [
    "00139.png": (health: 5, moveSpeed: 80.00, pattern: .sine, canShoot: true, name: "OrangeStorm", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 2.1),
    "00140.png": (health: 5, moveSpeed: 80.00, pattern: .straight, canShoot: true, name: "NavyBlue", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 1.3),
    "00250.png": (health: 2, moveSpeed: 56.00, pattern: .zigzag, canShoot: true, name: "JumpingFrog", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 2.5),
    "00260.png": (health: 4, moveSpeed: 40.00, pattern: .straight, canShoot: true, name: "FireBall", shotType: "bullet", shotsAtOnce: 2, shootFrequency: 1.2),
    "00270.png": (health: 2, moveSpeed: 48.00, pattern: .zigzag, canShoot: true, name: "LemonTree", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 2.2),
    "00280.png": (health: 2, moveSpeed: 120.00, pattern: .sine, canShoot: true, name: "YellowStar", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 1.2),
    "00290.png": (health: 8, moveSpeed: 120.00, pattern: .zigzag, canShoot: true, name: "BlackArrow", shotType: "rocket", shotsAtOnce: 2, shootFrequency: 1.0),
    "00300.png": (health: 5, moveSpeed: 96.00, pattern: .straight, canShoot: true, name: "DarkFire", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 1.1),
    "00310.png": (health: 4, moveSpeed: 40.00, pattern: .sine, canShoot: true, name: "SteelEye", shotType: "bomb", shotsAtOnce: 2, shootFrequency: 2.0),
    "00320.png": (health: 1, moveSpeed: 48.00, pattern: .random, canShoot: false, name: "Butterfly", shotType: "-", shotsAtOnce: 1, shootFrequency: 1.0),
    "00330.png": (health: 10, moveSpeed: 144.00, pattern: .straight, canShoot: true, name: "BoolShid", shotType: "bullet", shotsAtOnce: 4, shootFrequency: 2.1),
    "00340.png": (health: 2, moveSpeed: 64.00, pattern: .straight, canShoot: true, name: "MilitaryStep", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 1.0),
    "00350.png": (health: 3, moveSpeed: 40.00, pattern: .sine, canShoot: false, name: "DesertFox", shotType: "-", shotsAtOnce: 1, shootFrequency: 1.0),
    "00355.png": (health: 2, moveSpeed: 60.00, pattern: .random, canShoot: true, name: "Cigarillo", shotType: "rocket", shotsAtOnce: 1, shootFrequency: 2.0),
    "00360.png": (health: 2, moveSpeed: 72.00, pattern: .zigzag, canShoot: true, name: "LimboDance", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 2.5),
    "00410.png": (health: 50, moveSpeed: 24.00, pattern: .straight, canShoot: false, name: "CloudFrank", shotType: "-", shotsAtOnce: 2, shootFrequency: 1.0),
    "00450.png": (health: 1, moveSpeed: 24.00, pattern: .sine, canShoot: false, name: "Walti", shotType: "-", shotsAtOnce: 1, shootFrequency: 1.0),
    "00500.png": (health: 1, moveSpeed: 56.00, pattern: .random, canShoot: true, name: "Baby", shotType: "bomb", shotsAtOnce: 1, shootFrequency: 1.0)
]

// Custom enemy plane class with health, movement, and shooting logic
class EnemyPlane: SKSpriteNode {
    enum MovementPattern {
        case straight, zigzag, sine, random
    }
    var health: Int = 1
    var initialHealth: Int = 1
    var moveSpeed: CGFloat = 80
    var movementPattern: MovementPattern = .straight
    var shootCooldown: TimeInterval = 1.5
    var lastShotTime: TimeInterval = 0
    var horizontalDir: CGFloat = 1
    var verticalSpeed: CGFloat = 64
    var horizontalSpeed: CGFloat = 32
    var canShoot: Bool = false
    var shotType: String = "bullet"
    var shotsAtOnce: Int = 1
    var shootFrequency: Double = 1.5
    weak var gameScene: GameScene?

    convenience init(texture: SKTexture, health: Int, speed: CGFloat, pattern: MovementPattern, canShoot: Bool, shotType: String, shotsAtOnce: Int, shootFrequency: Double, gameScene: GameScene) {
        self.init(texture: texture, color: .clear, size: texture.size())
        self.health = health
        self.initialHealth = health
        self.moveSpeed = speed
        self.movementPattern = pattern
        self.canShoot = canShoot
        self.shotType = shotType
        self.shotsAtOnce = shotsAtOnce
        self.shootFrequency = shootFrequency
        self.gameScene = gameScene
        self.verticalSpeed = speed
        self.horizontalSpeed = speed / 2
        self.lastShotTime = 0
        self.horizontalDir = Bool.random() ? 1 : -1
    }

    func update(_ dt: CGFloat, currentTime: TimeInterval, canShoot: Bool) {
        guard let scene = gameScene else { return }
        // Move vertically (scroll)
        self.position.y -= verticalSpeed * dt
        // Move horizontally based on pattern
        switch movementPattern {
        case .straight:
            self.position.x += horizontalDir * horizontalSpeed * dt
        case .zigzag:
            self.position.x += horizontalDir * horizontalSpeed * dt
            if Int(position.y) % 120 == 0 { horizontalDir *= -1 }
        case .sine:
            self.position.x += sin(position.y / 40) * horizontalSpeed * dt
        case .random:
            self.position.x += CGFloat.random(in: -2...2) * horizontalSpeed * dt
        }
        // Bounce off edges
        let minX = self.size.width / 2
        let maxX = scene.size.width - self.size.width / 2
        if self.position.x < minX { self.position.x = minX; horizontalDir = 1 }
        if self.position.x > maxX { self.position.x = maxX; horizontalDir = -1 }
        // Shooting
        if canShoot && self.canShoot && currentTime - lastShotTime > shootFrequency {
            shoot()
            lastShotTime = currentTime
        }
    }

    func shoot() {
        guard let scene = gameScene else { return }
        for i in 0..<shotsAtOnce {
            let bulletImage: String
            switch shotType {
            case "rocket": bulletImage = "RedRocketEnemy.png"
            case "bomb": bulletImage = "BigBomb.png"
            default: bulletImage = "FastBullet2.png"
            }
            let bullet = SKSpriteNode(imageNamed: bulletImage)
            bullet.setScale(1.0)
            // Spread shots horizontally if more than one
            let spread: CGFloat = shotsAtOnce > 1 ? CGFloat(i - shotsAtOnce/2) * 20 * scene.scaledTileWidth / 60  : 0
            bullet.position = CGPoint(x: self.position.x + spread, y: self.position.y - self.size.height / 2)
            bullet.zPosition = 10
            
            switch shotType {
            case "rocket": bullet.size = CGSize(width: scene.scaledTileWidth / 60 * 10/2, height: scene.scaledTileHeight / 60 * 16/2)
            case "bomb": bullet.size = CGSize(width: scene.scaledTileWidth / 60 * 13/2, height: scene.scaledTileHeight / 60 * 13/2)
            default: bullet.size = CGSize(width: scene.scaledTileWidth / 60 * 13/2, height: scene.scaledTileHeight / 60 * 13/2)
            }

            bullet.name = "enemyBullet"
            scene.addChild(bullet)
            let moveDistance = scene.size.height + 100
            let moveDuration: Double
            if shotType == "bomb" {
                moveDuration = scene.enemyBombDuration // configurable bomb speed
            } else {
                moveDuration = Double(moveDistance) / Double(scene.bulletSpeed)
            }
            let moveAction = SKAction.moveBy(x: 0, y: -moveDistance, duration: moveDuration)
            let removeAction = SKAction.removeFromParent()
            bullet.run(SKAction.sequence([moveAction, removeAction]))
        }
        let sound = SKAction.playSoundFileNamed("laser_enemy.caf", waitForCompletion: false)
        scene.run(sound)
    }
}

// Helper functions for spawning and updating enemy planes
extension GameScene {
    func spawnEnemyPlanesSmart() {
        guard enemyPlanes.count < maxEnemies else { return }
        let availableSlots = mapWidth
        var usedSlots: Set<Int> = []
        for _ in 0..<maxEnemies {
            var col: Int
            repeat {
                col = Int.random(in: 0..<availableSlots)
            } while usedSlots.contains(col)
            usedSlots.insert(col)
            let texture = enemyPlaneTextures.randomElement() ?? SKTexture()
            let filename = texture.description.components(separatedBy: " '").last?.components(separatedBy: "'").first ?? ""
            // Use config if available, else randomize
            let config = enemyTypeConfig[filename] ?? (health: Int.random(in: 1...3), moveSpeed: CGFloat(80), pattern: EnemyPlane.MovementPattern.straight, canShoot: Bool.random(), name: "Unknown", shotType: "bullet", shotsAtOnce: 1, shootFrequency: 1.5)
            let enemy = EnemyPlane(texture: texture, health: config.health, speed: config.moveSpeed, pattern: config.pattern, canShoot: config.canShoot, shotType: config.shotType, shotsAtOnce: config.shotsAtOnce, shootFrequency: config.shootFrequency, gameScene: self)
            enemy.name = filename  // Store the plane type for kill tracking
            enemy.size = CGSize(width: self.scaledTileWidth / 60 * 32, height: self.scaledTileHeight / 60 * 32)
            let screenWidth = size.width
            let scaledTileWidth = screenWidth / CGFloat(mapWidth)
            let x = CGFloat(col) * scaledTileWidth + scaledTileWidth / 2
            let y = size.height + enemy.size.height / 2
            enemy.position = CGPoint(x: x, y: y)
            enemy.zPosition = 5
            addChild(enemy)
            enemyPlanes.append(enemy)
        }
    }

    func updateEnemyPlanesSmart(_ dt: CGFloat, currentTime: TimeInterval) {
        let visibleMinY = scrollOffset
        let visibleMaxY = scrollOffset + CGFloat(visibleRows) * scaledTileHeight
        
        for case let enemy as EnemyPlane in enemyPlanes {
            let isVisible = true //enemy.position.y >= visibleMinY && enemy.position.y < visibleMaxY
            enemy.update(dt, currentTime: currentTime, canShoot: isVisible)
        }
        // Remove enemies that leave the bottom
        enemyPlanes.removeAll { enemy in
            if enemy.position.y < -enemy.size.height {
                enemy.removeFromParent()
                return true
            }
            return false
        }
    }
}
