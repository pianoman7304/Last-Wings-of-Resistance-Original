import UIKit
import SpriteKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let skView = SKView(frame: window!.bounds)
        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        skView.isMultipleTouchEnabled = true
        
        let viewController = UIViewController()
        viewController.view = skView
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}
