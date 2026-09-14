import Foundation

public struct Certificate: Codable, Identifiable, Equatable {
    public let milestoneID: String
    public let earnedAt: Date
    public let totalMetersAtCrossing: Double

    public var id: String { milestoneID }

    public init(milestoneID: String, earnedAt: Date, totalMetersAtCrossing: Double) {
        self.milestoneID = milestoneID; self.earnedAt = earnedAt; self.totalMetersAtCrossing = totalMetersAtCrossing
    }

    public var milestone: Milestone? { Milestone.stateLines.first { $0.id == milestoneID } }
}

/// Everything that is persisted between launches.
public struct OdometerState: Codable, Equatable {
    public var totalMeters: Double
    public var startedAt: Date
    public var certificates: [Certificate]

    public init(totalMeters: Double = 0, startedAt: Date = Date(), certificates: [Certificate] = []) {
        self.totalMeters = totalMeters; self.startedAt = startedAt; self.certificates = certificates
    }

    /// Advances the total and issues certificates for any milestones crossed. Returns the new certificates.
    @discardableResult
    public mutating func advance(to newTotal: Double, now: Date = Date()) -> [Certificate] {
        let earned = Set(certificates.map(\.milestoneID))
        let fresh = Milestone.newlyCrossed(from: totalMeters, to: newTotal)
            .filter { !earned.contains($0.id) }
            .map { Certificate(milestoneID: $0.id, earnedAt: now, totalMetersAtCrossing: newTotal) }
        totalMeters = newTotal
        certificates.append(contentsOf: fresh)
        return fresh
    }
}
