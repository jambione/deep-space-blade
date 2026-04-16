import SpriteKit

final class PlayerShip: SKSpriteNode {

    // MARK: - Weapon state
    enum WeaponLevel: Int {
        case single = 1, double = 2, triple = 3, quad = 4
    }

    private(set) var weaponLevel: WeaponLevel = .single
    private(set) var hasShield: Bool = false
    private(set) var activePowerUps: Set<PowerUpKind> = []

    // MARK: - Movement
    var targetX: CGFloat?
    private let moveSpeed: CGFloat = 420
    private let minX: CGFloat = 30
    private var maxX: CGFloat = 0

    // MARK: - Firing
    private var fireCooldown: TimeInterval = 0
    private let baseFireRate: TimeInterval = 0.14
    weak var projectilePool: ProjectilePool?

    // MARK: - Shield node
    private var shieldNode: SKShapeNode?

    init(screenSize: CGSize) {
        maxX = screenSize.width - 30
        let texture = SKTexture(imageNamed: "player_ship_0")
        super.init(texture: texture, color: .clear, size: CGSize(width: 48, height: 52))
        name = "player"
        position = CGPoint(x: screenSize.width / 2, y: 80)
        setupPhysics()
        setupAnimation()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupAnimation() {
        let frames = (0..<3).map { SKTexture(imageNamed: "player_ship_\($0)") }
        run(.repeatForever(.animate(with: frames, timePerFrame: 0.12)))
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 36, height: 36))
        physicsBody?.categoryBitMask    = CollisionMask.player
        physicsBody?.contactTestBitMask = CollisionMask.enemyBullet | CollisionMask.enemy
        physicsBody?.collisionBitMask   = 0
        physicsBody?.isDynamic = false
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        moveTowardTarget(deltaTime: deltaTime)

        if fireCooldown > 0 {
            fireCooldown -= deltaTime
        }
    }

    private func moveTowardTarget(deltaTime: TimeInterval) {
        guard let tx = targetX else { return }
        let dx = tx - position.x
        let step = moveSpeed * CGFloat(deltaTime)
        if abs(dx) <= step {
            position.x = tx
        } else {
            position.x += dx > 0 ? step : -step
        }
        position.x = position.x.clamped(to: minX...maxX)
    }

    // MARK: - Firing

    func tryFire() -> [Projectile] {
        guard fireCooldown <= 0 else { return [] }
        fireCooldown = baseFireRate
        return spawnBullets()
    }

    private func spawnBullets() -> [Projectile] {
        guard let pool = projectilePool else { return [] }
        var bullets: [Projectile] = []

        let offsets: [CGFloat]
        switch weaponLevel {
        case .single: offsets = [0]
        case .double: offsets = [-10, 10]
        case .triple: offsets = [-16, 0, 16]
        case .quad:   offsets = [-22, -7, 7, 22]
        }

        for xOff in offsets {
            let b = pool.acquire(isPlayer: true)
            b.position = CGPoint(x: position.x + xOff, y: position.y + 30)
            bullets.append(b)
        }
        return bullets
    }

    // MARK: - Damage

    /// Returns true if ship is destroyed (no lives deducted here — caller decides).
    func takeDamage() -> Bool {
        if hasShield {
            removeShield()
            return false
        }
        explode()
        return true
    }

    // MARK: - Power-ups

    func applyPowerUp(_ kind: PowerUpKind) {
        switch kind {
        case .doubleShot:   weaponLevel = .double
        case .tripleShot:   weaponLevel = .triple
        case .shield:       addShield()
        case .speedBoost:   activePowerUps.insert(.speedBoost)
        case .extraLife:    GameState.shared.addLife()
        default:            activePowerUps.insert(kind)
        }
    }

    // MARK: - Shield

    private func addShield() {
        guard !hasShield else { return }
        hasShield = true
        let shield = SKShapeNode(circleOfRadius: 32)
        shield.strokeColor = .cyan
        shield.fillColor = SKColor.cyan.withAlphaComponent(0.15)
        shield.lineWidth = 2
        shield.name = "shield"
        addChild(shield)
        shieldNode = shield
    }

    private func removeShield() {
        hasShield = false
        shieldNode?.removeFromParent()
        shieldNode = nil
    }

    // MARK: - VFX

    func explode() {
        let emitter = SKEmitterNode(fileNamed: "PlayerExplosion") ?? makeSimpleExplosion()
        emitter.position = position
        parent?.addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 1.5), .removeFromParent()]))
        isHidden = true
    }

    func respawn(at point: CGPoint) {
        position = point
        isHidden = false
        weaponLevel = .single
        removeShield()
        // Brief invincibility flash
        run(.sequence([
            .repeat(.sequence([.fadeAlpha(to: 0.3, duration: 0.1),
                               .fadeAlpha(to: 1.0, duration: 0.1)]), count: 6)
        ]))
    }

    private func makeSimpleExplosion() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = SKTexture(imageNamed: "spark")
        e.numParticlesToEmit = 30
        e.particleLifetime = 0.6
        e.particleSpeed = 120
        e.particleSpeedRange = 80
        e.emissionAngleRange = .pi * 2
        e.particleAlphaSpeed = -1.5
        e.particleScale = 0.4
        e.particleScaleRange = 0.3
        return e
    }
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
