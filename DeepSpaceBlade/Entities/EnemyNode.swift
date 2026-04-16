import SpriteKit

final class EnemyNode: SKSpriteNode {

    // MARK: - State machine

    enum State {
        case entering       // flying in along entry path
        case formation      // holding formation position
        case diving         // executing a dive attack
        case returning      // flying back to formation slot
        case dying          // death animation playing
    }

    // MARK: - Properties

    let blueprint: EnemyBlueprint
    private(set) var health: Int
    var formationSlot: Int = -1
    var formationTarget: CGPoint = .zero
    private(set) var state: State = .entering
    private var fireTimer: TimeInterval = 0

    weak var projectilePool: ProjectilePool?

    // MARK: - Init

    init(blueprint: EnemyBlueprint) {
        self.blueprint = blueprint
        self.health = blueprint.health
        // Exported frames are named spriteName_0, spriteName_1, …
        let firstName = blueprint.animationFrameCount > 1
            ? "\(blueprint.spriteName)_0"
            : blueprint.spriteName
        let texture = SKTexture(imageNamed: firstName)
        super.init(texture: texture, color: .clear,
                   size: CGSize(width: blueprint.width, height: blueprint.height))
        name = "enemy_\(blueprint.id)"
        setupPhysics()
        setupAnimation()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: blueprint.width * 0.8,
                                                         height: blueprint.height * 0.8))
        physicsBody?.categoryBitMask    = CollisionMask.enemy
        physicsBody?.contactTestBitMask = CollisionMask.playerBullet | CollisionMask.player
        physicsBody?.collisionBitMask   = 0
        physicsBody?.isDynamic = false
    }

    private func setupAnimation() {
        guard blueprint.animationFrameCount > 1 else { return }
        let frames = (0..<blueprint.animationFrameCount).map {
            SKTexture(imageNamed: "\(blueprint.spriteName)_\($0)")
        }
        run(.repeatForever(.animate(with: frames, timePerFrame: 0.1)))
    }

    // MARK: - State transitions

    func enterFormation() {
        state = .formation
    }

    func beginDive(path: CGPath, speed: CGFloat, completion: @escaping () -> Void) {
        guard state == .formation else { return }
        state = .diving
        physicsBody?.isDynamic = true
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false,
                                     speed: speed)
        run(.sequence([follow, .run {
            self.physicsBody?.isDynamic = false
            completion()
        }]))
    }

    func returnToFormation(completion: @escaping () -> Void) {
        state = .returning
        let move = SKAction.move(to: formationTarget,
                                 duration: TimeInterval(distance(to: formationTarget) / 200))
        run(.sequence([move, .run {
            self.state = .formation
            completion()
        }]))
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard state != .dying else { return }

        if state == .formation {
            nudgeToFormationTarget(deltaTime: deltaTime)
        }

        updateFireTimer(deltaTime: deltaTime, playerPosition: playerPosition)
    }

    private func nudgeToFormationTarget(deltaTime: TimeInterval) {
        let speed: CGFloat = 120
        let dx = formationTarget.x - position.x
        let dy = formationTarget.y - position.y
        let dist = hypot(dx, dy)
        guard dist > 1 else { return }
        let step = speed * CGFloat(deltaTime)
        position.x += (dx / dist) * min(step, dist)
        position.y += (dy / dist) * min(step, dist)
    }

    private func updateFireTimer(deltaTime: TimeInterval, playerPosition: CGPoint) {
        let pattern = blueprint.fire
        guard pattern.type != .none else { return }
        guard state == .formation || (state == .diving && pattern.type != .none) else { return }

        fireTimer -= deltaTime
        if fireTimer <= 0 {
            fireTimer = pattern.cooldown + Double.random(in: -0.2...0.2)
            spawnBullets(toward: playerPosition)
        }
    }

    // MARK: - Firing

    private func spawnBullets(toward target: CGPoint) {
        guard let pool = projectilePool else { return }
        let pattern = blueprint.fire
        // Append _0 to match exported frame filenames
        let bulletSprite = "\(pattern.bulletSprite)_0"
        let muzzle = CGPoint(x: position.x, y: position.y - blueprint.height / 2)

        switch pattern.type {
        case .none: break

        case .single, .aimed:
            let b = pool.acquire(isPlayer: false, spriteName: bulletSprite)
            b.position = muzzle
            if pattern.type == .aimed {
                let angle = atan2(target.y - position.y, target.x - position.x)
                b.zRotation = angle - .pi / 2
                b.physicsBody?.velocity = CGVector(dx: cos(angle) * pattern.bulletSpeed,
                                                   dy: sin(angle) * pattern.bulletSpeed)
            }

        case .spread:
            let count = 3
            let half = pattern.spreadAngle / 2
            for i in 0..<count {
                let frac = count > 1 ? CGFloat(i) / CGFloat(count - 1) : 0.5
                let angleDeg = -half + frac * pattern.spreadAngle
                let angle = angleDeg * .pi / 180 - .pi / 2
                let b = pool.acquire(isPlayer: false, spriteName: bulletSprite)
                b.position = muzzle
                b.physicsBody?.velocity = CGVector(dx: cos(angle) * pattern.bulletSpeed,
                                                   dy: sin(angle) * pattern.bulletSpeed)
            }

        case .burst:
            for i in 0..<pattern.burstCount {
                let delay = TimeInterval(i) * 0.06
                run(.wait(forDuration: delay)) { [weak self] in
                    guard let self, let pool = self.projectilePool else { return }
                    let b = pool.acquire(isPlayer: false, spriteName: bulletSprite)
                    b.position = CGPoint(x: self.position.x, y: self.position.y - self.blueprint.height / 2)
                    b.physicsBody?.velocity = CGVector(dx: 0, dy: -self.blueprint.fire.bulletSpeed)
                }
            }

        case .laser:
            NotificationCenter.default.post(name: .enemyFireLaser, object: self)
        }
    }

    // MARK: - Damage

    /// Returns true when the enemy is killed.
    @discardableResult
    func takeDamage(_ amount: Int) -> Bool {
        guard state != .dying else { return false }
        health -= amount
        if health <= 0 {
            die()
            return true
        }
        run(.sequence([.colorize(with: .white, colorBlendFactor: 1, duration: 0.04),
                       .colorize(withColorBlendFactor: 0, duration: 0.06)]))
        return false
    }

    private func die() {
        state = .dying
        physicsBody = nil
        spawnDrops()
        GameState.shared.addScore(blueprint.scoreValue)
        let explosion = makeExplosion()
        explosion.position = position
        parent?.addChild(explosion)
        explosion.run(.sequence([.wait(forDuration: 0.8), .removeFromParent()]))
        run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        NotificationCenter.default.post(name: .enemyDied, object: self)
    }

    private func spawnDrops() {
        for drop in blueprint.drops {
            guard Double.random(in: 0...1) < drop.chance else { continue }
            NotificationCenter.default.post(name: .spawnPowerUp,
                                            object: nil,
                                            userInfo: ["itemId": drop.itemId,
                                                       "position": position])
        }
    }

    private func makeExplosion() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.numParticlesToEmit = 20
        e.particleLifetime = 0.5
        e.particleSpeed = 80
        e.particleSpeedRange = 60
        e.emissionAngleRange = .pi * 2
        e.particleAlphaSpeed = -2
        e.particleScale = 0.3
        e.particleColor = .orange
        return e
    }

    // MARK: - Helpers

    private func distance(to point: CGPoint) -> CGFloat {
        hypot(point.x - position.x, point.y - position.y)
    }
}

extension SKNode {
    func run(_ action: SKAction, completion: @escaping () -> Void) {
        run(.sequence([action, .run(completion)]))
    }
}

extension Notification.Name {
    static let enemyDied      = Notification.Name("dsb.enemyDied")
    static let enemyFireLaser = Notification.Name("dsb.enemyFireLaser")
    static let spawnPowerUp   = Notification.Name("dsb.spawnPowerUp")
    static let waveCleared    = Notification.Name("dsb.waveCleared")
    static let levelCleared   = Notification.Name("dsb.levelCleared")
}
