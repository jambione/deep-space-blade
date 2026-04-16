import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false

        let menu = MenuScene(size: skView.bounds.size)
        menu.scaleMode = .resizeFill
        skView.presentScene(menu)
    }

    override func loadView() {
        view = SKView(frame: UIScreen.main.bounds)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
