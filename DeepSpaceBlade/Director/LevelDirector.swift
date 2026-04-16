import SpriteKit

/// Loads levels.json + blueprints.json, sequences waves, and broadcasts level events.
final class LevelDirector {

    private let levels: [LevelDefinition]
    private let blueprintMap: [String: EnemyBlueprint]

    private var currentLevelIndex: Int = 0
    private var currentWaveIndex: Int = 0
    private var activeWave: WaveDirector?

    private weak var scene: SKScene?
    private weak var pool: ProjectilePool?

    var onWaveStart: ((Int) -> Void)?        // wave number (1-based)
    var onLevelComplete: ((LevelDefinition) -> Void)?
    var onAllLevelsComplete: (() -> Void)?

    // MARK: - Init

    init(scene: SKScene, pool: ProjectilePool) throws {
        self.scene = scene
        self.pool = pool
        let data = try LevelDirector.loadGameData()
        self.levels = data.levels
        self.blueprintMap = Dictionary(uniqueKeysWithValues: data.blueprints.map { ($0.id, $0) })
    }

    private static func loadGameData() throws -> (levels: [LevelDefinition],
                                                   blueprints: [EnemyBlueprint]) {
        let levels = try load([LevelDefinition].self, fromJSON: "levels")
        let blueprints = try load([EnemyBlueprint].self, fromJSON: "blueprints")
        return (levels, blueprints)
    }

    private static func load<T: Decodable>(_ type: T.Type, fromJSON name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw LevelError.missingFile(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Control

    func startLevel(_ index: Int) {
        currentLevelIndex = index
        currentWaveIndex = 0
        spawnNextWave()
    }

    func startCurrentLevel() { startLevel(currentLevelIndex) }

    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        activeWave?.update(deltaTime: deltaTime, playerPosition: playerPosition)
    }

    // MARK: - Wave sequencing

    private func spawnNextWave() {
        guard let scene = scene, let pool = pool else { return }
        let level = levels[currentLevelIndex]

        guard currentWaveIndex < level.waves.count else {
            // All waves done — check for boss
            if let bossId = level.bossId {
                spawnBoss(id: bossId, scene: scene, pool: pool)
            } else {
                levelComplete()
            }
            return
        }

        let waveDef = level.waves[currentWaveIndex]
        let director = WaveDirector(wave: waveDef,
                                    blueprints: blueprintMap,
                                    scene: scene,
                                    pool: pool)
        director.onCleared = { [weak self] in
            self?.waveCleared()
        }
        director.spawn(screenSize: scene.size)
        activeWave = director
        onWaveStart?(currentWaveIndex + 1)
    }

    private func waveCleared() {
        NotificationCenter.default.post(name: .waveCleared, object: nil)
        currentWaveIndex += 1
        // Brief pause before next wave
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.spawnNextWave()
        }
    }

    private func levelComplete() {
        let level = levels[currentLevelIndex]
        NotificationCenter.default.post(name: .levelCleared, object: nil)
        onLevelComplete?(level)
        GameState.shared.advanceLevel()
        currentLevelIndex += 1
        if currentLevelIndex >= levels.count {
            onAllLevelsComplete?()
        }
    }

    // MARK: - Boss

    private func spawnBoss(id: String, scene: SKScene, pool: ProjectilePool) {
        guard let bp = blueprintMap[id] else {
            levelComplete()
            return
        }
        let boss = EnemyNode(blueprint: bp)
        boss.projectilePool = pool
        boss.formationTarget = CGPoint(x: scene.size.width / 2,
                                       y: scene.size.height * 0.75)
        boss.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 100)
        scene.addChild(boss)
        boss.run(.move(to: boss.formationTarget, duration: 1.5)) {
            boss.enterFormation()
        }
        // Boss cleared callback
        let obs = NotificationCenter.default.addObserver(
            forName: .enemyDied, object: boss, queue: .main) { [weak self] _ in
                self?.levelComplete()
        }
        _ = obs  // held by notification center
    }

    // MARK: - Accessors

    var currentLevel: LevelDefinition? {
        guard currentLevelIndex < levels.count else { return nil }
        return levels[currentLevelIndex]
    }

    var totalLevels: Int { levels.count }

    enum LevelError: Error {
        case missingFile(String)
    }
}
