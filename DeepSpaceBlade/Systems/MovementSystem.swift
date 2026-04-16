import SpriteKit

/// Builds SKAction dive paths and entry paths for enemy formations.
final class MovementSystem {

    // MARK: - Entry Paths

    /// Returns an SKAction that flies the enemy from off-screen to its formation slot.
    static func entryAction(style: EntryStyle,
                            destination: CGPoint,
                            screenSize: CGSize,
                            speed: CGFloat,
                            customPoints: [PathPoint]? = nil) -> SKAction {
        switch style {
        case .swoopFromLeft:
            return swoopAction(from: CGPoint(x: -60, y: screenSize.height * 0.9),
                               to: destination, speed: speed)
        case .swoopFromRight:
            return swoopAction(from: CGPoint(x: screenSize.width + 60, y: screenSize.height * 0.9),
                               to: destination, speed: speed)
        case .dropFromTop:
            return dropAction(destination: destination, screenSize: screenSize, speed: speed)
        case .spiralIn:
            return spiralAction(destination: destination, screenSize: screenSize, speed: speed)
        case .custom:
            if let pts = customPoints, pts.count >= 2 {
                return customPathAction(points: pts, screenSize: screenSize, speed: speed)
            }
            return swoopAction(from: CGPoint(x: -60, y: screenSize.height * 0.9),
                               to: destination, speed: speed)
        }
    }

    /// Follows a designer-drawn Catmull-Rom path (normalized points → screen space).
    static func customPathAction(points: [PathPoint],
                                 screenSize: CGSize,
                                 speed: CGFloat) -> SKAction {
        let screenPts = points.map { $0.toScreen(screenSize) }
        let path = CGMutablePath()
        path.move(to: screenPts[0])
        let n = screenPts.count
        for i in 0..<(n - 1) {
            let p0 = screenPts[max(0, i - 1)]
            let p1 = screenPts[i]
            let p2 = screenPts[i + 1]
            let p3 = screenPts[min(n - 1, i + 2)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6,
                              y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6,
                              y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        // Approximate arc length for timing
        var arcLen: CGFloat = 0
        for i in 1..<n {
            arcLen += hypot(screenPts[i].x - screenPts[i-1].x,
                            screenPts[i].y - screenPts[i-1].y)
        }
        return .follow(path, asOffset: false, orientToPath: false,
                       duration: TimeInterval(arcLen / speed))
    }

    private static func swoopAction(from start: CGPoint, to end: CGPoint, speed: CGFloat) -> SKAction {
        let mid = CGPoint(x: (start.x + end.x) / 2 + (end.y - start.y) * 0.4,
                          y: (start.y + end.y) / 2)
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: mid)
        let dist = hypot(end.x - start.x, end.y - start.y) * 1.2
        return .follow(path, asOffset: false, orientToPath: false,
                       duration: TimeInterval(dist / speed))
    }

    private static func dropAction(destination: CGPoint,
                                   screenSize: CGSize,
                                   speed: CGFloat) -> SKAction {
        let start = CGPoint(x: destination.x, y: screenSize.height + 60)
        let dist = abs(start.y - destination.y)
        return .sequence([
            .move(to: start, duration: 0),
            .move(to: destination, duration: TimeInterval(dist / speed))
        ])
    }

    private static func spiralAction(destination: CGPoint,
                                     screenSize: CGSize,
                                     speed: CGFloat) -> SKAction {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.6)
        let startAngle: CGFloat = .pi * 2
        let endAngle: CGFloat = 0
        let radius: CGFloat = 140
        let steps = 32
        let path = CGMutablePath()
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = startAngle + (endAngle - startAngle) * t
            let r = radius * (1 - t * 0.6)
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else       { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.addLine(to: destination)
        return .follow(path, asOffset: false, orientToPath: false,
                       duration: TimeInterval(radius * .pi * 2 / speed))
    }

    // MARK: - Dive Paths

    static func diveAction(type: DivePatternDef.DiveType,
                           from origin: CGPoint,
                           playerX: CGFloat,
                           screenSize: CGSize,
                           speed: CGFloat) -> CGPath {
        switch type {
        case .straight:    return straightDive(from: origin, screenSize: screenSize)
        case .sinusoidal:  return sinusoidalDive(from: origin, screenSize: screenSize)
        case .loop:        return loopDive(from: origin, screenSize: screenSize)
        case .swoop:       return swoopDive(from: origin, toward: playerX, screenSize: screenSize)
        case .kamikaze:    return kamikazeDive(from: origin, toward: CGPoint(x: playerX, y: 60))
        }
    }

    private static func straightDive(from: CGPoint, screenSize: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: CGPoint(x: from.x, y: -60))
        return path
    }

    private static func sinusoidalDive(from: CGPoint, screenSize: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        let amplitude: CGFloat = 80
        let steps = 40
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = from.y - t * (from.y + 60)
            let x = from.x + sin(t * .pi * 3) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    private static func loopDive(from: CGPoint, screenSize: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        // Dive down, loop around, return upward then dive off bottom
        let cx = from.x
        let cy = from.y - 120
        let r: CGFloat = 80
        path.addLine(to: CGPoint(x: cx, y: cy + r))
        path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                    startAngle: .pi / 2, endAngle: -.pi / 2, clockwise: false)
        path.addLine(to: CGPoint(x: cx, y: -60))
        return path
    }

    private static func swoopDive(from: CGPoint, toward playerX: CGFloat, screenSize: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        let ctrl = CGPoint(x: playerX, y: from.y - 200)
        let end  = CGPoint(x: playerX + CGFloat.random(in: -60...60), y: -60)
        path.addQuadCurve(to: end, control: ctrl)
        return path
    }

    private static func kamikazeDive(from: CGPoint, toward target: CGPoint) -> CGPath {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: target)
        path.addLine(to: CGPoint(x: target.x, y: -60))
        return path
    }

    // MARK: - Formation Oscillation

    /// Gentle left-right drift applied to all enemies in formation.
    static func formationDrift(amplitude: CGFloat = 30,
                               period: TimeInterval = 4.0) -> SKAction {
        .repeatForever(.sequence([
            .moveBy(x:  amplitude, y: 0, duration: period / 2),
            .moveBy(x: -amplitude, y: 0, duration: period / 2)
        ]))
    }
}
