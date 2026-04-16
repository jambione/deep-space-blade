import CoreGraphics
import Foundation

// MARK: - Level

struct LevelDefinition: Codable {
    let id: Int
    let name: String
    let backgroundName: String
    let musicTrack: String
    let waves: [WaveDefinition]
    let bossId: String?
}

// MARK: - Wave

struct WaveDefinition: Codable {
    let spawns: [EnemySpawn]
    let formation: FormationLayout
    let entryStyle: EntryStyle
    /// Seconds the formation holds before enemies begin diving.
    let holdTime: TimeInterval
    /// Custom entry path points from the Path Designer (normalized 0-1, y-up).
    let entryPoints: [PathPoint]?
    /// Optional mirrored entry path (right-side column enters from the other side).
    let mirrorEntryPoints: [PathPoint]?
}

struct EnemySpawn: Codable {
    /// Blueprint ID to instantiate.
    let blueprintId: String
    /// Which formation slots (0-based, row-major) this enemy occupies.
    let slots: [Int]
}

struct FormationLayout: Codable {
    let rows: Int
    let cols: Int
    let spacingX: CGFloat
    let spacingY: CGFloat
    /// Anchor as fraction of screen (0-1). (0.5, 0.78) = upper-center.
    let anchorX: CGFloat
    let anchorY: CGFloat

    func slotPosition(index: Int, in screenSize: CGSize) -> CGPoint {
        let row = index / cols
        let col = index % cols
        let totalW = CGFloat(cols - 1) * spacingX
        let totalH = CGFloat(rows - 1) * spacingY
        let originX = screenSize.width * anchorX - totalW / 2
        let originY = screenSize.height * anchorY - totalH / 2
        return CGPoint(x: originX + CGFloat(col) * spacingX,
                       y: originY + CGFloat(row) * spacingY)
    }
}

enum EntryStyle: String, Codable {
    case swoopFromLeft
    case swoopFromRight
    case dropFromTop
    case spiralIn
    case custom   // path defined by entryPoints array
}

/// Normalized coordinate (0-1), SpriteKit y-up convention.
struct PathPoint: Codable {
    let x: CGFloat
    let y: CGFloat

    func toScreen(_ size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

// MARK: - Enemy Blueprint

struct EnemyBlueprint: Codable, Identifiable {
    let id: String
    let displayName: String
    let spriteName: String
    let health: Int
    let speed: CGFloat
    let scoreValue: Int
    let width: CGFloat
    let height: CGFloat
    let animationFrameCount: Int
    let fire: FirePatternDef
    let dive: DivePatternDef
    let drops: [LootDrop]
}

struct FirePatternDef: Codable {
    let type: FireType
    let cooldown: TimeInterval
    let bulletSpeed: CGFloat
    let bulletSprite: String
    let spreadAngle: CGFloat   // degrees, used by .spread
    let burstCount: Int        // used by .burst

    enum FireType: String, Codable {
        case none, single, spread, burst, aimed, laser
    }
}

struct DivePatternDef: Codable {
    let type: DiveType
    let speed: CGFloat
    let fireWhileDiving: Bool

    enum DiveType: String, Codable {
        case straight, sinusoidal, loop, swoop, kamikaze
    }
}

struct LootDrop: Codable {
    let itemId: String
    /// Drop probability 0.0 – 1.0
    let chance: Double
}

// MARK: - Power-ups

enum PowerUpKind: String, Codable {
    case doubleShot
    case tripleShot
    case shield
    case speedBoost
    case bomb
    case laser
    case extraLife
}

struct PowerUpDefinition: Codable {
    let id: String
    let kind: PowerUpKind
    let duration: TimeInterval  // 0 = permanent
    let spriteName: String
}

// MARK: - Data Registry

struct GameData: Codable {
    let blueprints: [EnemyBlueprint]
    let powerUps: [PowerUpDefinition]
}
