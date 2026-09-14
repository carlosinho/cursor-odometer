import Foundation

/// A cursor position in global screen points.
public struct CursorPoint: Equatable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// Turns successive cursor positions into accumulated physical distance in meters.
///
/// Rules:
/// - The first sample only establishes a starting point.
/// - A sample on a different screen than the previous one is a jump, not travel, and is not counted.
/// - A single move longer than `teleportFraction` of the screen diagonal is treated as a teleport
///   (sleep/wake, screen sharing, hot corners) and is not counted.
/// - Movement on an unsupported screen is not counted.
public struct DistanceAccumulator {
    public private(set) var totalMeters: Double
    public let teleportFraction: Double
    private var last: (point: CursorPoint, screenID: UInt32)?

    public init(totalMeters: Double = 0, teleportFraction: Double = 0.5) {
        self.totalMeters = totalMeters
        self.teleportFraction = teleportFraction
    }

    /// Records a new cursor position. Returns the meters added by this sample (0 if rejected).
    @discardableResult
    public mutating func record(_ point: CursorPoint, on screen: ScreenCalibration) -> Double {
        defer { last = (point, screen.id) }
        guard let previous = last, previous.screenID == screen.id,
              let pointsPerMM = screen.pointsPerMillimeter else { return 0 }

        let dx = point.x - previous.point.x
        let dy = point.y - previous.point.y
        let distancePoints = (dx * dx + dy * dy).squareRoot()
        guard distancePoints > 0, distancePoints <= screen.diagonalPoints * teleportFraction else { return 0 }

        let meters = distancePoints / pointsPerMM / 1000
        totalMeters += meters
        return meters
    }

    /// Adds distance directly, bypassing cursor tracking (used for testing and simulation).
    public mutating func add(meters: Double) { totalMeters += max(0, meters) }

    public mutating func reset() { totalMeters = 0; last = nil }
}
