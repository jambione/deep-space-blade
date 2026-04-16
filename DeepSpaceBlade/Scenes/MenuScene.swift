import SpriteKit

final class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black
        addStarfield()
        addTitle()
        addByline()
        addStartButton()
        addHiScore()
    }

    private func addStarfield() {
        for _ in 0..<60 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.8))
            s.fillColor = .white
            s.strokeColor = .clear
            s.alpha = CGFloat.random(in: 0.2...0.9)
            s.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                 y: CGFloat.random(in: 0...size.height))
            addChild(s)
        }
    }

    private func addTitle() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "DEEP SPACE"
        title.fontSize = 38
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        addChild(title)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        sub.text = "BLADE"
        sub.fontSize = 58
        sub.fontColor = .cyan
        sub.position = CGPoint(x: size.width / 2, y: size.height * 0.56)
        addChild(sub)

        let byJMB = SKLabelNode(fontNamed: "AvenirNext-Medium")
        byJMB.text = "by JMB"
        byJMB.fontSize = 14
        byJMB.fontColor = SKColor.white.withAlphaComponent(0.5)
        byJMB.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        addChild(byJMB)

        // Pulsing glow on BLADE
        sub.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.7, duration: 0.9),
            .fadeAlpha(to: 1.0, duration: 0.9)
        ])))
    }

    private func addByline() { }

    private func addStartButton() {
        let btn = SKLabelNode(fontNamed: "AvenirNext-Bold")
        btn.text = "TAP TO START"
        btn.fontSize = 22
        btn.fontColor = .yellow
        btn.name = "startBtn"
        btn.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        addChild(btn)
        btn.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.2, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])))
    }

    private func addHiScore() {
        let hi = GameState.shared.hiScore
        guard hi > 0 else { return }
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "HI \(hi)"
        label.fontSize = 16
        label.fontColor = .orange
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let game = GameScene(size: size)
        game.scaleMode = .resizeFill
        GameState.shared.reset()
        view?.presentScene(game, transition: .fade(withDuration: 0.8))
    }
}
