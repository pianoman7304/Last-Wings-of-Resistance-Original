// ControllerInputHandler.swift
// Handles controller (gamepad) input for iOS, macOS, and tvOS using a PS5-type controller.
// Left joystick: move player airplane (X/Y)
// Cross (X/A): fire bullet
// Circle (O/B): fire rocket
// Calls GameScene methods directly for actions.

import Foundation
import GameController
#if os(iOS) || os(tvOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

class ControllerInputHandler {
    static let shared = ControllerInputHandler()
    private var controller: GCController?
    private weak var gameScene: GameScene?
    private weak var missionEndScene: MissionEndScene?
    private weak var imageSequenceScene: ImageSequenceScene?
    private weak var mainMenuScene: MainMenuScene?
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect), name: .GCControllerDidDisconnect, object: nil)
        // Try to get already-connected controller
        if let connected = GCController.controllers().first {
            self.controller = connected
        }
    }
    
    func registerGameScene(_ scene: GameScene) {
        self.gameScene = scene
        self.missionEndScene = nil
        //self.storyScene = nil
        //self.infoImageScene = nil
        self.imageSequenceScene = nil
        self.mainMenuScene = nil
        setupControllerHandlers()
    }
    
    func registerMissionEndScene(_ scene: MissionEndScene) {
        self.missionEndScene = scene
        self.gameScene = nil
        //self.storyScene = nil
        //self.infoImageScene = nil
        self.imageSequenceScene = nil
        self.mainMenuScene = nil
        setupControllerHandlers()
    }
    
    func registerImageSequenceScene(_ scene: ImageSequenceScene) {
        self.imageSequenceScene = scene
        self.gameScene = nil
        self.missionEndScene = nil
        //self.storyScene = nil
        //self.infoImageScene = nil
        self.mainMenuScene = nil
        setupControllerHandlers()
    }
    
    func registerMainMenuScene(_ scene: MainMenuScene) {
        self.mainMenuScene = scene
        self.gameScene = nil
        self.missionEndScene = nil
        //self.storyScene = nil
        //self.infoImageScene = nil
        self.imageSequenceScene = nil
        setupControllerHandlers()
    }
    
    func unregisterAllScenes() {
        self.gameScene = nil
        self.missionEndScene = nil
        self.imageSequenceScene = nil
        //self.storyScene = nil
        //self.infoImageScene = nil
        self.mainMenuScene = nil
        removeControllerHandlers()
    }
    
    func isControllerConnected() -> Bool {
        return GCController.controllers().count > 0
    }
    
    @objc private func controllerDidConnect(notification: Notification) {
        self.controller = GCController.controllers().first
        setupControllerHandlers()
    }
    
    @objc private func controllerDidDisconnect(notification: Notification) {
        self.controller = nil
        removeControllerHandlers()
    }
    
    private func setupControllerHandlers() {
        guard let controller = self.controller else { return }
        removeControllerHandlers()
        
        if let scene = self.gameScene {
            // Use extended gamepad profile
            controller.extendedGamepad?.leftThumbstick.valueChangedHandler = { [weak scene] _, xValue, yValue in
                scene?.movePlayerWithController(dx: CGFloat(xValue), dy: CGFloat(yValue))
            }
            controller.extendedGamepad?.buttonA.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.shootBullets()
                }
            }
            controller.extendedGamepad?.buttonB.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.shootRocket()
                }
            }
            // Add Triangle (buttonY) for exit popup - options button not working
            controller.extendedGamepad?.buttonY.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.showCustomExitPopup()
                }
            }
            // D-pad left/right for dialog navigation
            controller.extendedGamepad?.dpad.left.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed, scene?.customExitPopupNode != nil {
                    scene?.selectPreviousDialogOption()
                }
            }
            controller.extendedGamepad?.dpad.right.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed, scene?.customExitPopupNode != nil {
                    scene?.selectNextDialogOption()
                }
            }
            // X/Cross (buttonA) for dialog confirmation
            controller.extendedGamepad?.buttonA.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed, scene?.customExitPopupNode != nil {
                    scene?.confirmDialogSelection()
                } else if pressed {
                    scene?.shootBullets()
                }
            }
            // L2 button - simulate mission completion (same as 'P' key)
            controller.extendedGamepad?.leftTrigger.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    if let view = scene?.view {
                        print("Simulating mission completion", scene?.currentMissionNumber ?? 1, scene?.killsPerEnemyType ?? [:], scene?.score ?? 0, scene?.priorMissionsScore ?? 0, scene?.maxMissionNumber ?? 1)
                        HelperFunctions.transitionToMissionEndScene(
                            from: view,
                            currentMissionNumber: scene?.currentMissionNumber ?? 1,
                            killsPerEnemyType: scene?.killsPerEnemyType ?? [:],
                            score: scene?.score ?? 0,
                            priorMissionsScore: scene?.priorMissionsScore ?? 0,
                            maxMissionNumber: scene?.maxMissionNumber ?? 1,
                            playerDied: false
                        )
                        
                    }
                }
            }
        } else if let scene = self.missionEndScene {
            // MissionEndScene: A/B to navigate
            controller.extendedGamepad?.buttonA.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.controllerNavigate()
                }
            }
            controller.extendedGamepad?.buttonB.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.controllerNavigate()
                }
            }
        
        } else if let scene = self.mainMenuScene {
            // MainMenuScene: A/B select menu item, D-pad up/down to move, leftThumbstick with centering logic
            controller.extendedGamepad?.dpad.up.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.moveMenuSelection(up: true)
                }
            }
            controller.extendedGamepad?.dpad.down.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.moveMenuSelection(up: false)
                }
            }
            // Joystick centering logic
            var stickWasCentered = true
            controller.extendedGamepad?.leftThumbstick.valueChangedHandler = { [weak scene] _, xValue, yValue in
                let threshold: Float = 0.5
                if abs(yValue) < 0.3 {
                    stickWasCentered = true
                } else if stickWasCentered {
                    if yValue > threshold {
                        scene?.moveMenuSelection(up: true)
                        stickWasCentered = false
                    } else if yValue < -threshold {
                        scene?.moveMenuSelection(up: false)
                        stickWasCentered = false
                    }
                }
            }
            controller.extendedGamepad?.buttonA.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.handleMenuSelection()
                }
            }
            controller.extendedGamepad?.buttonB.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.handleMenuSelection()
                }
            }
            
        } else if let scene = self.imageSequenceScene {
            controller.extendedGamepad?.buttonA.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.controllerNavigate()
                }
            }
            controller.extendedGamepad?.buttonB.pressedChangedHandler = { [weak scene] _, _, pressed in
                if pressed {
                    scene?.controllerNavigate()
                }
            }
        }
        
    }
    
    private func removeControllerHandlers() {
        guard let controller = self.controller else { return }
        controller.extendedGamepad?.leftThumbstick.valueChangedHandler = nil
        controller.extendedGamepad?.buttonA.pressedChangedHandler = nil
        controller.extendedGamepad?.buttonB.pressedChangedHandler = nil
    }
    
    // For MainMenuScene: check if controller is connected
    static func isControllerAvailable() -> Bool {
        return GCController.controllers().count > 0
    }
}
