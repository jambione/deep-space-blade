import SpriteKit

struct CollisionMask {
    static let player:       UInt32 = 0x01
    static let enemy:        UInt32 = 0x02
    static let playerBullet: UInt32 = 0x04
    static let enemyBullet:  UInt32 = 0x08
    static let powerUp:      UInt32 = 0x10
}

protocol CollisionDelegate: AnyObject {
    func playerBulletHitEnemy(_ bullet: Projectile, enemy: EnemyNode)
    func enemyBulletHitPlayer(_ bullet: Projectile)
    func enemyHitPlayer(_ enemy: EnemyNode)
    func playerCollectedPowerUp(_ node: SKNode)
}

final class CollisionSystem: NSObject, SKPhysicsContactDelegate {

    weak var delegate: CollisionDelegate?

    func didBegin(_ contact: SKPhysicsContact) {
        // ordered() returns (lower bitmask, higher bitmask), so cases must be written
        // with the numerically smaller mask first:
        //   player=0x01  enemy=0x02  playerBullet=0x04  enemyBullet=0x08  powerUp=0x10
        let (a, b) = ordered(contact.bodyA, contact.bodyB)

        switch (a.categoryBitMask, b.categoryBitMask) {

        case (CollisionMask.player, CollisionMask.enemy):           // 0x01 vs 0x02
            guard let enemy = b.node as? EnemyNode else { return }
            delegate?.enemyHitPlayer(enemy)

        case (CollisionMask.player, CollisionMask.enemyBullet):     // 0x01 vs 0x08
            guard let bullet = b.node as? Projectile else { return }
            delegate?.enemyBulletHitPlayer(bullet)

        case (CollisionMask.player, CollisionMask.powerUp):         // 0x01 vs 0x10
            guard let powerNode = b.node else { return }
            delegate?.playerCollectedPowerUp(powerNode)

        case (CollisionMask.enemy, CollisionMask.playerBullet):     // 0x02 vs 0x04
            guard let enemy  = a.node as? EnemyNode,
                  let bullet = b.node as? Projectile else { return }
            delegate?.playerBulletHitEnemy(bullet, enemy: enemy)

        default:
            break
        }
    }

    // Returns bodies sorted lowest category first for stable matching.
    private func ordered(_ a: SKPhysicsBody, _ b: SKPhysicsBody)
        -> (SKPhysicsBody, SKPhysicsBody)
    {
        a.categoryBitMask <= b.categoryBitMask ? (a, b) : (b, a)
    }
}
