import SpriteKit

final class GameOverScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black

        let over = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        over.text = "GAME OVER"
        over.fontSize = 42
        over.fontColor = .red
        over.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
        addChild(over)

        let final_ = GameState.shared.score
        let score = SKLabelNode(fontNamed: "AvenirNext-Bold")
        score.text = "SCORE  \(final_)"
        score.fontSize = 24
        score.fontColor = .white
        score.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        addChild(score)

        let hi = GameState.shared.hiScore
        let hiLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hiLabel.text = "BEST  \(hi)"
        hiLabel.fontSize = 18
        hiLabel.fontColor = .orange
        hiLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.43)
        addChild(hiLabel)

        let tap = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tap.text = "TAP TO RETRY"
        tap.fontSize = 20
        tap.fontColor = .yellow
        tap.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        addChild(tap)
        tap.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.2, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let menu = MenuScene(size: size)
        menu.scaleMode = .resizeFill
        view?.presentScene(menu, transition: .fade(withDuration: 0.8))
    }
}
