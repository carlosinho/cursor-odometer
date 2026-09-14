import Foundation

/// Which family of units and milestones the app presents. Distance is always stored in meters.
public enum MeasurementSystem: String, Codable, CaseIterable, Identifiable {
    case us
    case metric

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .us: return "US"
        case .metric: return "Metric"
        }
    }

    /// The unit shown in the menu bar and headline.
    public var primaryUnit: DistanceUnit {
        switch self {
        case .us: return .miles
        case .metric: return .kilometers
        }
    }

    public var standardUnits: [DistanceUnit] {
        switch self {
        case .us: return [.miles, .feet]
        case .metric: return [.kilometers, .meters]
        }
    }

    /// The custom units to display given the user's selection (nil means the defaults).
    public func customUnits(enabledIDs: [String]?) -> [DistanceUnit] {
        let enabled = Set(enabledIDs ?? DistanceUnit.defaultCustomIDs)
        return DistanceUnit.customCatalog(for: self).filter { enabled.contains($0.id) }
    }

    /// Every milestone active under this system: universal ones plus the system-specific ladders.
    public var milestones: [Milestone] {
        switch self {
        case .us: return Milestone.universal + Milestone.usEarly + Milestone.stateLines
        case .metric: return Milestone.universal + Milestone.metricEarly + Milestone.countries
        }
    }

    /// Display title for a milestone category; the region ladder is named after its contents.
    public func title(for category: MilestoneCategory) -> String {
        guard category == .region else { return category.title }
        switch self {
        case .us: return "State lines"
        case .metric: return "Country crossings"
        }
    }
}
