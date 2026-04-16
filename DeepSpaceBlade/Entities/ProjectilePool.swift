import SpriteKit

final class Projectile: SKSpriteNode {
    var isPlayer: Bool = true

    static func make(isPlayer: Bool) -> Projectile {
        let name = isPlayer ? "bullet_player_0" : "bullet_enemy_0"
        let p = Projectile(imageNamed: name)
        p.isPlayer = isPlayer
        p.size = isPlayer ? CGSize(width: 6, height: 18) : CGSize(width: 8, height: 14)
        p.setupPhysics()
        return p
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.8,
                                                         height: size.height * 0.8))
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.linearDamping = 0
        if isPlayer {
            physicsBody?.categoryBitMask    = CollisionMask.playerBullet
            physicsBody?.contactTestBitMask = CollisionMask.enemy
            physicsBody?.velocity = CGVector(dx: 0, dy: 700)
        } else {
            physicsBody?.categoryBitMask    = CollisionMask.enemyBullet
            physicsBody?.contactTestBitMask = CollisionMask.player
            physicsBody?.velocity = CGVector(dx: 0, dy: -380)
        }
        physicsBody?.collisionBitMask = 0
    }

    func reset(isPlayer: Bool, spriteName: String? = nil) {
        self.isPlayer = isPlayer
        let defaultName = isPlayer ? "bullet_player_0" : "bullet_enemy_0"
        texture = SKTexture(imageNamed: spriteName ?? defaultName)
        size = isPlayer ? CGSize(width: 6, height: 18) : CGSize(width: 8, height: 14)
        setupPhysics()
        isHidden = false
        alpha = 1
    }
}

// MARK: -

final class ProjectilePool {
    private var playerPool: [Projectile] = []
    private var enemyPool: [Projectile] = []
    private weak var scene: SKScene?
    private let initialSize = 40

    init(scene: SKScene) {
        self.scene = scene
        fill(pool: &playerPool, isPlayer: true,  count: initialSize)
        fill(pool: &enemyPool,  isPlayer: false, count: initialSize)
    }

    private func fill(pool: inout [Projectile], isPlayer: Bool, count: Int) {
        for _ in 0..<count {
            let p = Projectile.make(isPlayer: isPlayer)
            p.isHidden = true
            scene?.addChild(p)
            pool.append(p)
        }
    }

    func acquire(isPlayer: Bool, spriteName: String? = nil) -> Projectile {
        let pool = isPlayer ? playerPool : enemyPool
        if let idx = pool.firstIndex(where: { $0.isHidden }) {
            let p = pool[idx]
            p.reset(isPlayer: isPlayer, spriteName: spriteName)
            return p
        }
        // Grow pool on demand
        let p = Projectile.make(isPlayer: isPlayer)
        p.reset(isPlayer: isPlayer, spriteName: spriteName)
        scene?.addChild(p)
        if isPlayer { playerPool.append(p) }
        else        { enemyPool.append(p) }
        return p
    }

    func recycle(_ projectile: Projectile) {
        projectile.isHidden = true
        projectile.removeAllActions()
        projectile.physicsBody?.velocity = .zero
        projectile.physicsBody?.categoryBitMask = 0   // prevent phantom contacts while off-screen
        projectile.position = CGPoint(x: -1000, y: -1000)
    }

    func recycleAllOutOfBounds(in screenSize: CGSize) {
        let margin: CGFloat = 80
        let all = playerPool + enemyPool
        for p in all where !p.isHidden {
            if p.position.y > screenSize.height + margin ||
               p.position.y < -margin ||
               p.position.x < -margin ||
               p.position.x > screenSize.width + margin {
                recycle(p)
            }
        }
    }
}
