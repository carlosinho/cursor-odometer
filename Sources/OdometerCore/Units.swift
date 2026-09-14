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
    /// 100 yards, goal line to goal line.
    public static let footballFields = DistanceUnit(id: "football", singular: "football field", plural: "football fields", metersPerUnit: 91.44)
    public static let eiffelTowers = DistanceUnit(id: "eiffel", singular: "Eiffel Tower", plural: "Eiffel Towers", metersPerUnit: 330)
    public static let goldenGates = DistanceUnit(id: "goldengate", singular: "Golden Gate Bridge", plural: "Golden Gate Bridges", metersPerUnit: 2737)
    public static let marathons = DistanceUnit(id: "marathon", singular: "marathon", plural: "marathons", metersPerUnit: 42195)

    public static let standard: [DistanceUnit] = [miles, kilometers, meters, feet]
    public static let custom: [DistanceUnit] = [footballFields, eiffelTowers, goldenGates, marathons]
}
