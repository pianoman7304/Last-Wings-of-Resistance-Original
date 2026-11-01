import SpriteKit

#if os(iOS)

protocol iPadInputDelegate: AnyObject {
    func didUpdateMoveDirection(_ direction: CGVector)
    func didPressFire1()
    func didPressFire2()
}

// Add protocol for pause button
protocol iPadInputDelegateWithPause: iPadInputDelegate {
    func didPressPause()
}

class iPadInputOverlay: SKNode {
    weak var delegate: iPadInputDelegate?

    // Joystick
    private let joystickBase = SKShapeNode(circleOfRadius: 50)
    private let joystickKnob = SKShapeNode(circleOfRadius: 30)
    private var isTouchingJoystick = false

    // Fire buttons
    private let fire1Button = SKShapeNode(circleOfRadius: 40)
    private let fire2Button = SKShapeNode(circleOfRadius: 40)

    // Pause button
    private var pauseButton: SKSpriteNode!

    private var joystickTouch: UITouch?
    private var fire1Touch: UITouch?
    private var fire2Touch: UITouch?

    override init() {
        super.init()
        isUserInteractionEnabled = true
        setupJoystick()
        setupFireButtons()
        setupPauseButton()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupJoystick() {
        joystickBase.fillColor = .gray
        joystickBase.alpha = 0.4
        let margin: CGFloat = 40
        let screenWidth = UIScreen.main.bounds.width
        let x = screenWidth - joystickBase.frame.width / 2 - margin
        let y = margin + joystickBase.frame.height / 2
        joystickBase.position = CGPoint(x: x, y: y)

        joystickKnob.fillColor = .white
        joystickKnob.alpha = 0.7
        joystickKnob.position = joystickBase.position

        addChild(joystickBase)
        addChild(joystickKnob)
    }
    
    // update position of joystick if needed as scene size changes in gamescne
    
    func updateJoystickPosition() {
        let margin: CGFloat = 70
        if let scene = self.scene {
            let x = scene.size.width - joystickBase.frame.width / 2 - margin
            let y = margin + joystickBase.frame.height / 2
            joystickBase.position = CGPoint(x: x, y: y)
            joystickKnob.position = joystickBase.position
        }
    }
    
    func updatePauseButtonPosition() {
        let margin: CGFloat = 24
        if let scene = self.scene {
            pauseButton.position = CGPoint(
                x: scene.size.width - pauseButton.size.width / 2 - margin,
                y: scene.size.height - pauseButton.size.height / 2 - margin
            )
        }
    }
    
    private func setupFireButtons() {
        fire1Button.fillColor = .white
        fire1Button.alpha = 0.3
        fire1Button.position = CGPoint(x: 120, y: 180) // Left side, adjust as needed
        fire1Button.name = "fire1"
        // Add label for fire1Button ("C")
        let fire1Label = SKLabelNode(text: "bullet")
        fire1Label.fontName = "AvenirNext-Bold"
        fire1Label.fontSize = 18
        fire1Label.fontColor = .black
        fire1Label.verticalAlignmentMode = .center
        fire1Label.horizontalAlignmentMode = .center
        fire1Button.addChild(fire1Label)
        addChild(fire1Button)

        fire2Button.fillColor = .white
        fire2Button.alpha = 0.3
        fire2Button.position = CGPoint(x: 220, y: 80) // Left side, adjust as needed
        fire2Button.name = "fire2"
        // Add label for fire2Button ("space")
        let fire2Label = SKLabelNode(text: "rocket")
        fire2Label.fontName = "AvenirNext-Bold"
        fire2Label.fontSize = 18
        fire2Label.fontColor = .black
        fire2Label.verticalAlignmentMode = .center
        fire2Label.horizontalAlignmentMode = .center
        fire2Button.addChild(fire2Label)
        addChild(fire2Button)
    }

    private func setupPauseButton() {
        let texture = SKTexture(imageNamed: "pause_icon")
        pauseButton = SKSpriteNode(texture: texture)
        pauseButton.size = CGSize(width: 32, height: 32)
        pauseButton.alpha = 0.3
        pauseButton.zPosition = 10000
        pauseButton.name = "pauseButton"
        // Position in upper right corner
        if let scene = self.scene {
            pauseButton.position = CGPoint(x: scene.size.width - 24, y: scene.size.height - 24)
        } else {
            let screen = UIScreen.main.bounds
            pauseButton.position = CGPoint(x: screen.width - 24, y: screen.height - 24)
        }
        addChild(pauseButton)
    }

    // Remove the following method, as SKNode does not have didMove(toParent:)
    // If you want to update the pause button position when the scene size changes,
    // consider calling a custom method from the scene when needed.

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let pauseButton = pauseButton, pauseButton.contains(location) {
                (delegate as? iPadInputDelegateWithPause)?.didPressPause()
                return
            }
            if joystickBase.contains(location) && joystickTouch == nil {
                joystickTouch = touch
                updateJoystick(location)
            } else if fire1Button.contains(location) && fire1Touch == nil {
                fire1Touch = touch
                delegate?.didPressFire1()
            } else if fire2Button.contains(location) && fire2Touch == nil {
                fire2Touch = touch
                delegate?.didPressFire2()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                let location = touch.location(in: self)
                updateJoystick(location)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == joystickTouch {
                joystickTouch = nil
                joystickKnob.position = joystickBase.position
                delegate?.didUpdateMoveDirection(.zero)
            }
            if touch == fire1Touch {
                fire1Touch = nil
            }
            if touch == fire2Touch {
                fire2Touch = nil
            }
        }
    }

    private func updateJoystick(_ location: CGPoint) {
        let basePos = joystickBase.position
        let dx = location.x - basePos.x
        let dy = location.y - basePos.y
        let distance = sqrt(dx*dx + dy*dy)
        let maxDistance: CGFloat = 50
        let angle = atan2(dy, dx)
        let limitedDistance = min(distance, maxDistance)
        let knobX = basePos.x + cos(angle) * limitedDistance
        let knobY = basePos.y + sin(angle) * limitedDistance
        joystickKnob.position = CGPoint(x: knobX, y: knobY)
        let direction = CGVector(dx: dx / maxDistance, dy: dy / maxDistance)
        delegate?.didUpdateMoveDirection(direction)
    }
}

#endif
