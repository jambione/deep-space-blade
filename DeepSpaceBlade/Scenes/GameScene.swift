import SpriteKit

final class GameScene: SKScene {

    // MARK: - Nodes
    private var player: PlayerShip!
    private var projectilePool: ProjectilePool!
    private var collisionSystem: CollisionSystem!
    private var levelDirector: LevelDirector!

    // MARK: - HUD
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var multiplierLabel: SKLabelNode!

    // MARK: - Touch
    private var touchX: CGFloat?
    private var isFiring: Bool = false

    // MARK: - State
    private var isPlayerAlive: Bool = true
    private var respawnTimer: TimeInterval = 0
    private let respawnDelay: TimeInterval = 1.8

    private var lastTime: TimeInterval = 0
    private var powerUpObserver: Any?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPhysics()
        setupBackground()
        setupPlayer()
        setupHUD()
        setupSystems()
        startLevel()
    }

    private func setupPhysics() {
        physicsWorld.gravity = .zero
        collisionSystem = CollisionSystem()
        collisionSystem.delegate = self
        physicsWorld.contactDelegate = collisionSystem
    }

    private func setupBackground() {
        let bg = SKSpriteNode(color: .black, size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        addChild(bg)
        addStarfield()
    }

    private func addStarfield() {
        guard let emitter = SKEmitterNode(fileNamed: "Starfield") else {
            addFallbackStars()
            return
        }
        emitter.position = CGPoint(x: size.width / 2, y: size.height + 20)
        emitter.zPosition = -90
        emitter.advanceSimulationTime(20)
        addChild(emitter)
    }

    private func addFallbackStars() {
        for _ in 0..<80 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                    y: CGFloat.random(in: 0...size.height))
            star.zPosition = -90
            addChild(star)
        }
    }

    private func setupPlayer() {
        projectilePool = ProjectilePool(scene: self)
        player = PlayerShip(screenSize: size)
        player.projectilePool = projectilePool
        player.zPosition = 10
        addChild(player)
    }

    private func setupHUD() {
        scoreLabel = makeHUDLabel(text: "0", x: size.width / 2, y: size.height - 30, fontSize: 20)
        livesLabel = makeHUDLabel(text: "♥♥♥", x: 60, y: size.height - 30, fontSize: 16)
        levelLabel = makeHUDLabel(text: "LEVEL 1", x: size.width - 60, y: size.height - 30, fontSize: 14)
        multiplierLabel = makeHUDLabel(text: "", x: size.width / 2, y: size.height - 52, fontSize: 13)
        multiplierLabel.fontColor = .yellow
    }

    private func makeHUDLabel(text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.zPosition = 100
        label.verticalAlignmentMode = .center
        addChild(label)
        return label
    }

    private func setupSystems() {
        do {
            levelDirector = try LevelDirector(scene: self, pool: projectilePool)
        } catch {
            fatalError("Failed to load level data: \(error)")
        }

        powerUpObserver = NotificationCenter.default.addObserver(
            forName: .spawnPowerUp, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let itemId = note.userInfo?["itemId"] as? String,
                  let pos    = note.userInfo?["position"] as? CGPoint else { return }
            self.spawnPowerUp(itemId: itemId, at: pos)
        }
    }

    private func spawnPowerUp(itemId: String, at pos: CGPoint) {
        let node = SKSpriteNode(imageNamed: "powerup_\(itemId)_0")
        node.size = CGSize(width: 22, height: 22)
        node.position = pos
        node.zPosition = 5
        node.name = "powerup"
        node.userData = NSMutableDictionary(dictionary: ["kind": itemId])

        let body = SKPhysicsBody(circleOfRadius: 11)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask    = CollisionMask.powerUp
        body.contactTestBitMask = CollisionMask.player
        body.collisionBitMask   = 0
        node.physicsBody = body

        addChild(node)
        node.run(.sequence([
            .moveBy(x: 0, y: -(size.height + 60), duration: 7.0),
            .removeFromParent()
        ]))
    }

    private func startLevel() {
        levelDirector.startCurrentLevel()
    }

    override func willMove(from view: SKView) {
        if let obs = powerUpObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime - lastTime, 0.05)
        lastTime = currentTime

        guard dt > 0 else { return }

        updatePlayer(dt: dt)
        levelDirector.update(deltaTime: dt, playerPosition: player.position)
        projectilePool.recycleAllOutOfBounds(in: size)
        updateHUD()
    }

    private func updatePlayer(dt: TimeInterval) {
        guard isPlayerAlive else {
            respawnTimer -= dt
            if respawnTimer <= 0 { respawnPlayer() }
            return
        }
        player.targetX = touchX
        player.update(deltaTime: dt)
        if isFiring {
            let bullets = player.tryFire()
            // Bullets are already added to scene via pool — just make visible
            _ = bullets
        }
    }

    private func updateHUD() {
        let state = GameState.shared
        scoreLabel.text = "\(state.score)"
        let hearts = String(repeating: "♥", count: state.lives)
        livesLabel.text = hearts
        levelLabel.text = "LEVEL \(state.level)"
        multiplierLabel.text = state.multiplier > 1 ? "×\(state.multiplier)" : ""
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = touches.first?.location(in: self).x
        isFiring = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = touches.first?.location(in: self).x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = nil
        isFiring = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchX = nil
        isFiring = false
    }

    // MARK: - Player death & respawn

    private func killPlayer() {
        guard isPlayerAlive else { return }
        isPlayerAlive = false
        player.takeDamage()
        GameState.shared.loseLife()

        if GameState.shared.isGameOver {
            showGameOver()
        } else {
            respawnTimer = respawnDelay
        }
    }

    private func respawnPlayer() {
        isPlayerAlive = true
        player.respawn(at: CGPoint(x: size.width / 2, y: 80))
    }

    // MARK: - Game Over

    private func showGameOver() {
        let overlay = GameOverScene(size: size)
        overlay.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 1.0)
        view?.presentScene(overlay, transition: transition)
    }
}

// MARK: - CollisionDelegate

extension GameScene: CollisionDelegate {

    func playerBulletHitEnemy(_ bullet: Projectile, enemy: EnemyNode) {
        projectilePool.recycle(bullet)
        enemy.takeDamage(1)
    }

    func enemyBulletHitPlayer(_ bullet: Projectile) {
        projectilePool.recycle(bullet)
        killPlayer()
    }

    func enemyHitPlayer(_ enemy: EnemyNode) {
        enemy.takeDamage(enemy.blueprint.health)
        killPlayer()
    }

    func playerCollectedPowerUp(_ node: SKNode) {
        guard let kindStr = node.userData?["kind"] as? String,
              let kind = PowerUpKind(rawValue: kindStr) else { return }
        player.applyPowerUp(kind)
        node.run(.sequence([.scale(to: 1.4, duration: 0.1),
                            .fadeOut(withDuration: 0.1),
                            .removeFromParent()]))
    }
}
