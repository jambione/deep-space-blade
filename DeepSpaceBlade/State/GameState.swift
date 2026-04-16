import Foundation
import Combine

final class GameState: ObservableObject {
    static let shared = GameState()

    @Published private(set) var score: Int = 0
    @Published private(set) var hiScore: Int = 0
    @Published private(set) var lives: Int = 3
    @Published private(set) var level: Int = 1
    @Published private(set) var multiplier: Int = 1

    private var comboTimer: Timer?
    private let hiScoreKey = "dsb.hiScore"

    private init() {
        hiScore = UserDefaults.standard.integer(forKey: hiScoreKey)
    }

    func addScore(_ base: Int) {
        score += base * multiplier
        if score > hiScore {
            hiScore = score
            UserDefaults.standard.set(hiScore, forKey: hiScoreKey)
        }
        incrementCombo()
    }

    func loseLife() {
        lives = max(0, lives - 1)
        resetCombo()
    }

    func addLife() {
        lives += 1
    }

    func incrementCombo() {
        multiplier = min(multiplier + 1, 8)
        comboTimer?.invalidate()
        comboTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.resetCombo()
        }
    }

    func resetCombo() {
        multiplier = 1
        comboTimer?.invalidate()
    }

    func advanceLevel() {
        level += 1
    }

    func reset() {
        score = 0
        lives = 3
        level = 1
        multiplier = 1
        comboTimer?.invalidate()
    }

    var isGameOver: Bool { lives <= 0 }
}
