import Testing
import Foundation
@testable import OdometerCore

private func approx(_ a: Double, _ b: Double, _ eps: Double = 1e-9) -> Bool { abs(a - b) <= eps }

@Suite struct CalibrationTests {
    @Test func pointsPerMillimeterFromWidths() {
        #expect(approx(pointsPerMillimeter(frameWidthPoints: 1710, physicalWidthMillimeters: 342)!, 5))
    }
    @Test func unsupportedWhenNoPhysicalSize() {
        #expect(pointsPerMillimeter(frameWidthPoints: 1710, physicalWidthMillimeters: 0) == nil)
        #expect(pointsPerMillimeter(frameWidthPoints: 1710, physicalWidthMillimeters: .nan) == nil)
    }
}

@Suite struct AccumulatorTests {
    // 5 points per mm -> 1000 points = 200 mm = 0.2 m
    let screen = ScreenCalibration(id: 1, widthPoints: 1000, heightPoints: 1000, pointsPerMillimeter: 5)
    let other = ScreenCalibration(id: 2, widthPoints: 1000, heightPoints: 1000, pointsPerMillimeter: 5)
    let unsupported = ScreenCalibration(id: 3, widthPoints: 1000, heightPoints: 1000, pointsPerMillimeter: nil)

    @Test func firstSampleCountsNothing() {
        var a = DistanceAccumulator()
        #expect(a.record(CursorPoint(x: 0, y: 0), on: screen) == 0)
        #expect(a.totalMeters == 0)
    }
    @Test func accumulatesStraightLine() {
        var a = DistanceAccumulator()
        a.record(CursorPoint(x: 0, y: 0), on: screen)
        a.record(CursorPoint(x: 300, y: 400), on: screen) // 500 points = 100 mm
        #expect(approx(a.totalMeters, 0.1))
    }
    @Test func screenChangeIsNotCounted() {
        var a = DistanceAccumulator()
        a.record(CursorPoint(x: 0, y: 0), on: screen)
        a.record(CursorPoint(x: 300, y: 400), on: other)
        #expect(a.totalMeters == 0)
        a.record(CursorPoint(x: 303, y: 404), on: other) // 5 points = 1 mm
        #expect(approx(a.totalMeters, 0.001))
    }
    @Test func teleportRejected() {
        var a = DistanceAccumulator()
        a.record(CursorPoint(x: 0, y: 0), on: screen)
        a.record(CursorPoint(x: 999, y: 999), on: screen) // more than half the diagonal
        #expect(a.totalMeters == 0)
    }
    @Test func unsupportedScreenIgnored() {
        var a = DistanceAccumulator()
        a.record(CursorPoint(x: 0, y: 0), on: unsupported)
        a.record(CursorPoint(x: 100, y: 0), on: unsupported)
        #expect(a.totalMeters == 0)
    }
    @Test func resetAndAdd() {
        var a = DistanceAccumulator(totalMeters: 5)
        a.add(meters: 2); a.add(meters: -3)
        #expect(a.totalMeters == 7)
        a.reset()
        #expect(a.totalMeters == 0)
    }
}

@Suite struct UnitsTests {
    @Test func conversions() {
        #expect(approx(DistanceUnit.miles.value(forMeters: 1609.344), 1))
        #expect(approx(DistanceUnit.footballFields.value(forMeters: 91.44 * 3), 3))
    }
    @Test func formatting() {
        let us = Locale(identifier: "en_US")
        #expect(DistanceUnit.footballFields.format(meters: 91.44, locale: us) == "1 football field")
        #expect(DistanceUnit.footballFields.format(meters: 91.44 * 2.5, locale: us) == "2.5 football fields")
        #expect(DistanceUnit.miles.format(meters: 1609.344 * 12345, locale: us) == "12,345 mi")
    }
}

@Suite struct MilestoneTests {
    @Test func idsUniqueAndCategoriesConsistent() {
        #expect(Set(Milestone.all.map(\.id)).count == Milestone.all.count)
        #expect(Milestone.stateLines.allSatisfy { $0.category == .region })
        #expect(Milestone.countries.allSatisfy { $0.category == .region })
        #expect(Milestone.universal.allSatisfy { $0.category != .region })
    }
    @Test func nextPerCategoryGivesOnePerCategoryInOrder() {
        let next = Milestone.nextPerCategory(after: 0, in: MeasurementSystem.us.milestones)
        #expect(next.map(\.category) == [.sport, .landmarks, .space, .region])
        #expect(next.map(\.id) == ["sport.footballUS", "landmark.eiffel", "space.karman", "state.DE"])
        let far = Milestone.nextPerCategory(after: 1e12, in: MeasurementSystem.us.milestones)
        #expect(far.isEmpty)
    }
    @Test func newlyCrossedIsHalfOpen() {
        let de = Milestone.stateLines[0]
        #expect(Milestone.newlyCrossed(from: 0, to: de.meters, in: Milestone.stateLines).map(\.id) == ["state.DE"])
        #expect(Milestone.newlyCrossed(from: de.meters, to: de.meters + 1, in: Milestone.stateLines).isEmpty)
    }
    @Test func nextMilestone() {
        #expect(Milestone.next(after: 0, in: Milestone.stateLines)?.id == "state.DE")
        #expect(Milestone.next(after: 0, in: Milestone.countries)?.id == "country.LI")
        #expect(Milestone.next(after: 1e12, in: Milestone.stateLines) == nil)
    }
    @Test func findHandlesLegacyBareStateCodes() {
        #expect(Milestone.find(id: "DE")?.title == "Delaware")
        #expect(Milestone.find(id: "country.DE")?.title == "Germany")
        #expect(Milestone.find(id: "state.DE")?.unit == .miles)
        #expect(Milestone.find(id: "country.DE")?.unit == .kilometers)
    }
}

@Suite struct MeasurementSystemTests {
    @Test func usAndMetricDifferInUnitsAndMilestones() {
        #expect(MeasurementSystem.us.primaryUnit == .miles)
        #expect(MeasurementSystem.metric.primaryUnit == .kilometers)
        let usFootball = MeasurementSystem.us.customUnits(enabledIDs: nil).first { $0.id == "football" }
        let metricFootball = MeasurementSystem.metric.customUnits(enabledIDs: nil).first { $0.id == "football" }
        #expect(usFootball?.metersPerUnit == 91.44)
        #expect(metricFootball?.metersPerUnit == 105)
        #expect(metricFootball?.plural == "football fields")
        #expect(MeasurementSystem.metric.milestones.contains { $0.id == "country.DE" })
        #expect(!MeasurementSystem.metric.milestones.contains { $0.id.hasPrefix("state.") })
        #expect(MeasurementSystem.metric.milestones.contains { $0.id == "sport.marathon" })
        #expect(MeasurementSystem.us.milestones.contains { $0.id == "sport.marathon" })
        #expect(MeasurementSystem.us.title(for: .region) == "State lines")
        #expect(MeasurementSystem.metric.title(for: .region) == "Country crossings")
    }
}

@Suite struct CustomUnitSelectionTests {
    @Test func catalogIsSortedAndUnique() {
        for system in MeasurementSystem.allCases {
            let c = DistanceUnit.customCatalog(for: system)
            #expect(c.map(\.metersPerUnit) == c.map(\.metersPerUnit).sorted())
            #expect(Set(c.map(\.id)).count == c.count)
            #expect(DistanceUnit.defaultCustomIDs.allSatisfy { id in c.contains { $0.id == id } })
        }
    }
    @Test func defaultsApplyUntilUserChooses() {
        var s = OdometerState()
        #expect(s.customUnits.map(\.id) == ["whale", "747", "football", "titanic", "eiffel", "goldengate", "marathon"])
        s.setCustomUnit("banana", enabled: true)
        s.setCustomUnit("marathon", enabled: false)
        #expect(s.customUnits.map(\.id) == ["banana", "whale", "747", "football", "titanic", "eiffel", "goldengate"])
        #expect(s.isCustomUnitEnabled("banana"))
        #expect(!s.isCustomUnitEnabled("marathon"))
        let data = try! JSONEncoder().encode(s)
        #expect(try! JSONDecoder().decode(OdometerState.self, from: data).customUnitIDs == s.customUnitIDs)
    }
}

@Suite struct StateTests {
    @Test func advanceIssuesCertificatesOnce() {
        var s = OdometerState()
        let ri = Milestone.stateLines[1].meters
        let fresh = s.advance(to: ri + 1)
        #expect(fresh.filter { $0.milestoneID.hasPrefix("state.") }.map(\.milestoneID) == ["state.DE", "state.RI"])
        #expect(fresh.contains { $0.milestoneID == "sport.marathon" })
        #expect(s.advance(to: ri + 2).isEmpty)
        #expect(s.certificates.count == fresh.count)
    }
    @Test func switchingSystemBackfillsAndFiltersCertificates() {
        var s = OdometerState()
        s.advance(to: 55_000) // past Delaware (48.3 km) and Liechtenstein (25 km), short of Luxembourg (57 km)
        let region = { (c: [Certificate]) in c.map(\.milestoneID).filter { $0.hasPrefix("state.") || $0.hasPrefix("country.") } }
        #expect(region(s.certificates) == ["state.DE"])
        let fresh = s.setSystem(.metric)
        #expect(fresh.map(\.milestoneID).sorted() == ["country.LI", "sport.firstKilometer", "sport.footballMetric"])
        #expect(region(s.certificatesForCurrentSystem) == ["country.LI"])
        #expect(s.setSystem(.metric).isEmpty)
        s.setSystem(.us)
        #expect(region(s.certificatesForCurrentSystem) == ["state.DE"])
        #expect(!s.certificatesForCurrentSystem.contains { $0.milestoneID == "country.LI" })
        #expect(s.certificatesForCurrentSystem.contains { $0.milestoneID == "sport.marathon" })
    }
    @Test func decodesStateWithoutSystemAsUS() throws {
        let json = #"{"certificates":[],"totalMeters":1,"startedAt":0}"#.data(using: .utf8)!
        #expect(try JSONDecoder().decode(OdometerState.self, from: json).system == .us)
    }
    @Test func roundTripsThroughJSON() throws {
        var s = OdometerState(totalMeters: 12.5, system: .metric)
        s.advance(to: 100_000)
        let data = try JSONEncoder().encode(s)
        #expect(try JSONDecoder().decode(OdometerState.self, from: data) == s)
    }
}
