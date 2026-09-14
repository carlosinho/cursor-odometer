import Foundation

public enum MilestoneCategory: String, Codable, CaseIterable, Identifiable {
    case sport, landmarks, space, region

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .sport: return "Sport"
        case .landmarks: return "Landmarks"
        case .space: return "Space"
        case .region: return "Region"
        }
    }
}

/// A real-world distance. When the odometer passes it, a certificate is issued.
public struct Milestone: Identifiable, Equatable {
    public let id: String
    public let category: MilestoneCategory
    public let title: String
    public let detail: String
    public let meters: Double

    public init(id: String, category: MilestoneCategory, title: String, detail: String, meters: Double) {
        self.id = id; self.category = category; self.title = title; self.detail = detail; self.meters = meters
    }

    /// A unit this milestone is naturally expressed in, or nil to use the active system's unit.
    public var unit: DistanceUnit? {
        if id.hasPrefix("state.") { return .miles }
        if id.hasPrefix("country.") { return .kilometers }
        return nil
    }

    // MARK: - Tables (all distances approximate; edit freely)

    /// Milestones that appear in every measurement system.
    public static let universal: [Milestone] = [
        // Sport
        m("sport.halfMarathon", .sport, "Half marathon", "Ran a half marathon", km: 21.0975),
        m("sport.channel", .sport, "English Channel", "Swam the English Channel", km: 34),
        m("sport.marathon", .sport, "First marathon", "Ran your first marathon", km: 42.195),
        m("sport.ironman", .sport, "Ironman", "Completed an Ironman triathlon", km: 226),
        m("sport.tour", .sport, "Tour de France", "Rode the Tour de France", km: 3500),
        // Landmarks
        m("landmark.eiffel", .landmarks, "Eiffel Tower", "Climbed the height of the Eiffel Tower", km: 0.330),
        m("landmark.burj", .landmarks, "Burj Khalifa", "Climbed the height of Burj Khalifa", km: 0.828),
        m("landmark.goldenGate", .landmarks, "Golden Gate Bridge", "Crossed the Golden Gate Bridge", km: 2.737),
        m("landmark.everest", .landmarks, "Mount Everest", "Climbed the height of Mount Everest", km: 8.849),
        m("landmark.manhattan", .landmarks, "Manhattan", "Walked the length of Manhattan", km: 21.5),
        m("landmark.geneva", .landmarks, "Lake Geneva", "Crossed Lake Geneva end to end", km: 73),
        m("landmark.panama", .landmarks, "Panama Canal", "Sailed the Panama Canal", km: 82),
        m("landmark.greatWall", .landmarks, "Great Wall of China", "Walked the Great Wall of China", km: 21_000),
        m("landmark.equator", .landmarks, "Around the Equator", "Circled the Earth at the Equator", km: 40_075),
        // Space
        m("space.karman", .space, "Edge of space", "Reached the Kármán line", km: 100),
        m("space.iss", .space, "Space Station", "Reached the altitude of the International Space Station", km: 400),
        m("space.moon", .space, "The Moon", "Traveled to the Moon", km: 384_400),
    ]

    /// Early milestones that depend on the measurement system.
    public static let usEarly: [Milestone] = [
        m("sport.footballUS", .sport, "Football field", "Ran the length of a football field", km: 0.09144),
        m("sport.firstMile", .sport, "First mile", "Traveled your first mile", km: 1.609344),
    ]
    public static let metricEarly: [Milestone] = [
        m("sport.footballMetric", .sport, "Football field", "Ran the length of a football field", km: 0.105),
        m("sport.firstKilometer", .sport, "First kilometer", "Traveled your first kilometer", km: 1),
    ]

    /// Approximate shortest straight-line crossings of US states.
    public static let stateLines: [Milestone] = [
        state("DE", "Delaware", "east to west", miles: 30),
        state("RI", "Rhode Island", "east to west", miles: 37),
        state("CT", "Connecticut", "north to south", miles: 70),
        state("NJ", "New Jersey", "east to west", miles: 70),
        state("VT", "Vermont", "east to west", miles: 80),
        state("MA", "Massachusetts", "north to south", miles: 113),
        state("WV", "West Virginia", "east to west", miles: 130),
        state("OH", "Ohio", "east to west", miles: 220),
        state("CO", "Colorado", "north to south", miles: 280),
        state("MT", "Montana", "east to west", miles: 630),
        state("TX", "Texas", "east to west", miles: 773),
    ]

    /// Approximate shortest straight-line crossings of European countries.
    public static let countries: [Milestone] = [
        country("LI", "Liechtenstein", "north to south", km: 25),
        country("LU", "Luxembourg", "east to west", km: 57),
        country("BE", "Belgium", "north to south", km: 140),
        country("NL", "Netherlands", "east to west", km: 200),
        country("CH", "Switzerland", "north to south", km: 220),
        country("AT", "Austria", "north to south", km: 294),
        country("DK", "Denmark", "north to south", km: 360),
        country("DE", "Germany", "east to west", km: 640),
        country("PL", "Poland", "east to west", km: 690),
        country("FR", "France", "east to west", km: 950),
        country("ES", "Spain", "east to west", km: 1000),
    ]

    public static let all: [Milestone] = universal + usEarly + metricEarly + stateLines + countries

    public static func find(id: String) -> Milestone? {
        // Certificates saved before milestones were namespaced used bare state codes.
        all.first { $0.id == id } ?? all.first { $0.id == "state.\(id)" }
    }

    // MARK: - Queries

    /// Milestones whose distance lies in (from, to].
    public static func newlyCrossed(from: Double, to: Double, in milestones: [Milestone]) -> [Milestone] {
        milestones.filter { $0.meters > from && $0.meters <= to }.sorted { $0.meters < $1.meters }
    }

    public static func next(after meters: Double, in milestones: [Milestone]) -> Milestone? {
        milestones.filter { $0.meters > meters }.min { $0.meters < $1.meters }
    }

    /// The closest upcoming milestone in each category, ordered by category.
    public static func nextPerCategory(after meters: Double, in milestones: [Milestone]) -> [Milestone] {
        MilestoneCategory.allCases.compactMap { category in
            next(after: meters, in: milestones.filter { $0.category == category })
        }
    }

    // MARK: - Builders

    private static func m(_ id: String, _ category: MilestoneCategory, _ title: String, _ detail: String, km: Double) -> Milestone {
        Milestone(id: id, category: category, title: title, detail: detail, meters: km * 1000)
    }

    private static func state(_ code: String, _ name: String, _ direction: String, miles: Double) -> Milestone {
        Milestone(id: "state.\(code)", category: .region, title: name, detail: "Crossed \(name) \(direction)",
                  meters: miles * DistanceUnit.miles.metersPerUnit)
    }

    private static func country(_ code: String, _ name: String, _ direction: String, km: Double) -> Milestone {
        Milestone(id: "country.\(code)", category: .region, title: name, detail: "Crossed \(name) \(direction)", meters: km * 1000)
    }
}
