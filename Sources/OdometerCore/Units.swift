import Foundation

public struct DistanceUnit: Identifiable, Equatable {
    public let id: String
    public let singular: String
    public let plural: String
    public let metersPerUnit: Double
    public let symbol: String?

    public init(id: String, singular: String, plural: String, metersPerUnit: Double, symbol: String? = nil) {
        self.id = id; self.singular = singular; self.plural = plural
        self.metersPerUnit = metersPerUnit; self.symbol = symbol
    }

    public func value(forMeters meters: Double) -> Double { meters / metersPerUnit }

    /// Human readable amount, e.g. "3.42 football fields" or "1.2 km".
    public func format(meters: Double, locale: Locale = .current) -> String {
        let v = value(forMeters: meters)
        let number = DistanceUnit.number(v, locale: locale)
        if let symbol { return "\(number) \(symbol)" }
        return "\(number) \(v == 1 ? singular : plural)"
    }

    static func number(_ v: Double, locale: Locale) -> String {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = v < 10 ? 2 : (v < 1000 ? 1 : 0)
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    public static let meters = DistanceUnit(id: "m", singular: "meter", plural: "meters", metersPerUnit: 1, symbol: "m")
    public static let kilometers = DistanceUnit(id: "km", singular: "kilometer", plural: "kilometers", metersPerUnit: 1000, symbol: "km")
    public static let feet = DistanceUnit(id: "ft", singular: "foot", plural: "feet", metersPerUnit: 0.3048, symbol: "ft")
    public static let miles = DistanceUnit(id: "mi", singular: "mile", plural: "miles", metersPerUnit: 1609.344, symbol: "mi")

    // MARK: Custom units

    /// American football: 100 yards, goal line to goal line.
    public static let footballFields = DistanceUnit(id: "football", singular: "football field", plural: "football fields", metersPerUnit: 91.44)
    /// Association football: the standard 105 m pitch length. Deliberately still called a football field.
    public static let footballPitches = DistanceUnit(id: "football", singular: "football field", plural: "football fields", metersPerUnit: 105)

    public static let bananas = DistanceUnit(id: "banana", singular: "banana", plural: "bananas", metersPerUnit: 0.18)
    public static let schoolBuses = DistanceUnit(id: "bus", singular: "school bus", plural: "school buses", metersPerUnit: 13.7)
    public static let blueWhales = DistanceUnit(id: "whale", singular: "blue whale", plural: "blue whales", metersPerUnit: 30)
    public static let olympicPools = DistanceUnit(id: "pool", singular: "Olympic pool", plural: "Olympic pools", metersPerUnit: 50)
    public static let jumboJets = DistanceUnit(id: "747", singular: "Boeing 747", plural: "Boeing 747s", metersPerUnit: 71)
    public static let statuesOfLiberty = DistanceUnit(id: "liberty", singular: "Statue of Liberty", plural: "Statues of Liberty", metersPerUnit: 93)
    public static let greatPyramids = DistanceUnit(id: "pyramid", singular: "Great Pyramid", plural: "Great Pyramids", metersPerUnit: 139)
    public static let titanics = DistanceUnit(id: "titanic", singular: "Titanic", plural: "Titanics", metersPerUnit: 269)
    public static let eiffelTowers = DistanceUnit(id: "eiffel", singular: "Eiffel Tower", plural: "Eiffel Towers", metersPerUnit: 330)
    public static let empireStates = DistanceUnit(id: "empire", singular: "Empire State Building", plural: "Empire State Buildings", metersPerUnit: 443)
    public static let burjKhalifas = DistanceUnit(id: "burj", singular: "Burj Khalifa", plural: "Burj Khalifas", metersPerUnit: 828)
    public static let goldenGates = DistanceUnit(id: "goldengate", singular: "Golden Gate Bridge", plural: "Golden Gate Bridges", metersPerUnit: 2737)
    public static let centralParks = DistanceUnit(id: "centralpark", singular: "Central Park", plural: "Central Parks", metersPerUnit: 4000)
    public static let everests = DistanceUnit(id: "everest", singular: "Mount Everest", plural: "Mount Everests", metersPerUnit: 8849)
    public static let marathons = DistanceUnit(id: "marathon", singular: "marathon", plural: "marathons", metersPerUnit: 42195)
    public static let channelTunnels = DistanceUnit(id: "chunnel", singular: "Channel Tunnel", plural: "Channel Tunnels", metersPerUnit: 50450)
    public static let lightSeconds = DistanceUnit(id: "lightsecond", singular: "light-second", plural: "light-seconds", metersPerUnit: 299_792_458)

    /// Every custom unit a user can enable, smallest first. The football field length follows the system.
    public static func customCatalog(for system: MeasurementSystem) -> [DistanceUnit] {
        let football = system == .us ? footballFields : footballPitches
        return [bananas, schoolBuses, blueWhales, olympicPools, jumboJets, football, statuesOfLiberty, greatPyramids,
                titanics, eiffelTowers, empireStates, burjKhalifas, goldenGates, centralParks, everests, marathons,
                channelTunnels, lightSeconds].sorted { $0.metersPerUnit < $1.metersPerUnit }
    }

    /// Custom units shown until the user picks their own.
    public static let defaultCustomIDs: [String] = ["football", "whale", "747", "titanic", "eiffel", "goldengate", "marathon"]
}
