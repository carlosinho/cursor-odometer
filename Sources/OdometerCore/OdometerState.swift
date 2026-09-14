import Foundation

public struct Certificate: Codable, Identifiable, Equatable {
    public let milestoneID: String
    public let earnedAt: Date
    public let totalMetersAtCrossing: Double

    public var id: String { milestoneID }

    public init(milestoneID: String, earnedAt: Date, totalMetersAtCrossing: Double) {
        self.milestoneID = milestoneID; self.earnedAt = earnedAt; self.totalMetersAtCrossing = totalMetersAtCrossing
    }

    public var milestone: Milestone? { Milestone.find(id: milestoneID) }
}

/// Everything that is persisted between launches.
public struct OdometerState: Codable, Equatable {
    public var totalMeters: Double
    public var startedAt: Date
    public var certificates: [Certificate]
    public var system: MeasurementSystem
    /// Ids of enabled custom units; nil means the default set.
    public var customUnitIDs: [String]?

    public init(totalMeters: Double = 0, startedAt: Date = Date(), certificates: [Certificate] = [],
                system: MeasurementSystem = .us, customUnitIDs: [String]? = nil) {
        self.totalMeters = totalMeters; self.startedAt = startedAt
        self.certificates = certificates; self.system = system; self.customUnitIDs = customUnitIDs
    }

    enum CodingKeys: String, CodingKey { case totalMeters, startedAt, certificates, system, customUnitIDs }

    public var customUnits: [DistanceUnit] { system.customUnits(enabledIDs: customUnitIDs) }

    public func isCustomUnitEnabled(_ id: String) -> Bool {
        (customUnitIDs ?? DistanceUnit.defaultCustomIDs).contains(id)
    }

    public mutating func setCustomUnit(_ id: String, enabled: Bool) {
        var ids = customUnitIDs ?? DistanceUnit.defaultCustomIDs
        ids.removeAll { $0 == id }
        if enabled { ids.append(id) }
        customUnitIDs = ids
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalMeters = try c.decode(Double.self, forKey: .totalMeters)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        certificates = try c.decode([Certificate].self, forKey: .certificates)
        system = try c.decodeIfPresent(MeasurementSystem.self, forKey: .system) ?? .us
        customUnitIDs = try c.decodeIfPresent([String].self, forKey: .customUnitIDs)
    }

    /// Certificates earned under the current system, in the order they were earned.
    public var certificatesForCurrentSystem: [Certificate] {
        let ids = Set(system.milestones.map(\.id))
        return certificates.filter { ids.contains($0.milestoneID) }
    }

    /// Advances the total and issues certificates for any milestones crossed. Returns the new certificates.
    @discardableResult
    public mutating func advance(to newTotal: Double, now: Date = Date()) -> [Certificate] {
        let fresh = issue(Milestone.newlyCrossed(from: totalMeters, to: newTotal, in: system.milestones), total: newTotal, now: now)
        totalMeters = newTotal
        return fresh
    }

    /// Switches systems and backfills certificates for milestones of the new system already passed.
    @discardableResult
    public mutating func setSystem(_ newSystem: MeasurementSystem, now: Date = Date()) -> [Certificate] {
        system = newSystem
        return issue(Milestone.newlyCrossed(from: 0, to: totalMeters, in: newSystem.milestones), total: totalMeters, now: now)
    }

    private mutating func issue(_ milestones: [Milestone], total: Double, now: Date) -> [Certificate] {
        let earned = Set(certificates.map(\.milestoneID))
        let fresh = milestones
            .filter { !earned.contains($0.id) }
            .map { Certificate(milestoneID: $0.id, earnedAt: now, totalMetersAtCrossing: total) }
        certificates.append(contentsOf: fresh)
        return fresh
    }
}
