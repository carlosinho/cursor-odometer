import Foundation

/// A real-world crossing distance. When the odometer passes it, a certificate is issued.
public struct Milestone: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let detail: String
    public let meters: Double

    public init(id: String, title: String, detail: String, miles: Double) {
        self.id = id; self.title = title; self.detail = detail
        self.meters = miles * DistanceUnit.miles.metersPerUnit
    }

    /// Approximate shortest straight-line crossings of US states, smallest first.
    public static let stateLines: [Milestone] = [
        Milestone(id: "DE", title: "Delaware", detail: "Crossed Delaware east to west", miles: 30),
        Milestone(id: "RI", title: "Rhode Island", detail: "Crossed Rhode Island east to west", miles: 37),
        Milestone(id: "CT", title: "Connecticut", detail: "Crossed Connecticut north to south", miles: 70),
        Milestone(id: "NJ", title: "New Jersey", detail: "Crossed New Jersey east to west", miles: 70),
        Milestone(id: "VT", title: "Vermont", detail: "Crossed Vermont east to west", miles: 80),
        Milestone(id: "MA", title: "Massachusetts", detail: "Crossed Massachusetts north to south", miles: 113),
        Milestone(id: "WV", title: "West Virginia", detail: "Crossed West Virginia east to west", miles: 130),
        Milestone(id: "OH", title: "Ohio", detail: "Crossed Ohio east to west", miles: 220),
        Milestone(id: "CO", title: "Colorado", detail: "Crossed Colorado north to south", miles: 280),
        Milestone(id: "MT", title: "Montana", detail: "Crossed Montana east to west", miles: 630),
        Milestone(id: "TX", title: "Texas", detail: "Crossed Texas east to west", miles: 773),
    ]

    /// Milestones whose distance lies in (from, to].
    public static func newlyCrossed(from: Double, to: Double, in milestones: [Milestone] = stateLines) -> [Milestone] {
        milestones.filter { $0.meters > from && $0.meters <= to }
    }

    public static func next(after meters: Double, in milestones: [Milestone] = stateLines) -> Milestone? {
        milestones.filter { $0.meters > meters }.min { $0.meters < $1.meters }
    }
}
