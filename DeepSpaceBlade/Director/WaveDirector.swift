import SpriteKit

/// Spawns one wave of enemies, manages formation state, and triggers dives.
final class WaveDirector {

    private let wave: WaveDefinition
    private let blueprintMap: [String: EnemyBlueprint]
    private weak var scene: SKScene?
    private weak var pool: ProjectilePool?

    private var enemies: [EnemyNode] = []
    private var diveQueue: [EnemyNode] = []
    private var holdTimer: TimeInterval = 0
    private var diveInterval: TimeInterval = 2.5
    private var diveTimer: TimeInterval = 0
    private var isHolding: Bool = true

    var onCleared: (() -> Void)?

    init(wave: WaveDefinition,
         blueprints: [String: EnemyBlueprint],
         scene: SKScene,
         pool: ProjectilePool) {
        self.wave = wave
        self.blueprintMap = blueprints
        self.scene = scene
        self.pool = pool
        holdTimer = wave.holdTime
    }

    // MARK: - Spawn

    func spawn(screenSize: CGSize) {
        var slotAssignments: [Int: String] = [:]

        for spawn in wave.spawns {
            for slot in spawn.slots {
                slotAssignments[slot] = spawn.blueprintId
            }
        }

        let layout = wave.formation
        let totalSlots = layout.rows * layout.cols

        for slot in 0..<totalSlots {
            guard let bpId = slotAssignments[slot],
                  let bp = blueprintMap[bpId] else { continue }

            let enemy = EnemyNode(blueprint: bp)
            enemy.projectilePool = pool
            enemy.formationSlot = slot
            enemy.formationTarget = layout.slotPosition(index: slot, in: screenSize)

            // Alternate mirror path for even slots when a mirror path is defined
            let useMirror = (slot % 2 == 1) && wave.mirrorEntryPoints != nil
            let pts = useMirror ? wave.mirrorEntryPoints : wave.entryPoints
            let entryAction = MovementSystem.entryAction(
                style: wave.entryStyle,
                destination: enemy.formationTarget,
                screenSize: screenSize,
                speed: bp.speed,
                customPoints: pts
            )

            // Stagger entry slightly by slot index
            let stagger = SKAction.wait(forDuration: TimeInterval(slot) * 0.08)
            scene?.addChild(enemy)

            enemy.run(.sequence([stagger, entryAction, .run {
                enemy.enterFormation()
            }]))

            enemies.append(enemy)
        }

        diveQueue = enemies.shuffled()
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        let live = enemies.filter { $0.parent != nil && $0.state != .dying }

        if live.isEmpty {
            onCleared?()
            return
        }

        for e in live {
            e.update(deltaTime: deltaTime, playerPosition: playerPosition)
        }

        if isHolding {
            holdTimer -= deltaTime
            if holdTimer <= 0 { isHolding = false }
            return
        }

        diveTimer -= deltaTime
        if diveTimer <= 0 {
            diveTimer = diveInterval
            triggerDive(playerPosition: playerPosition)
        }
    }

    // MARK: - Dive Logic

    private func triggerDive(playerPosition: CGPoint) {
        guard let scene = scene else { return }
        let screenSize = scene.size

        // Pick 1-2 formation enemies to dive
        let candidates = enemies.filter { $0.state == .formation && $0.parent != nil }
        guard !candidates.isEmpty else { return }

        let count = Bool.random() && candidates.count > 1 ? 2 : 1
        for enemy in candidates.prefix(count) {
            let divePath = MovementSystem.diveAction(
                type: enemy.blueprint.dive.type,
                from: enemy.position,
                playerX: playerPosition.x,
                screenSize: screenSize,
                speed: enemy.blueprint.dive.speed
            )
            enemy.beginDive(path: divePath, speed: enemy.blueprint.dive.speed) {
                // Enemy exited screen — recycle or return to formation
                if enemy.parent != nil {
                    enemy.returnToFormation { }
                }
            }
        }
    }

    // MARK: - Cleanup

    func removeAll() {
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
    }
}
