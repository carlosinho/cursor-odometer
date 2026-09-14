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
    @Test func stateLinesSorted() {
        let m = Milestone.stateLines.map(\.meters)
        #expect(m == m.sorted())
    }
    @Test func newlyCrossedIsHalfOpen() {
        let de = Milestone.stateLines[0]
        #expect(Milestone.newlyCrossed(from: 0, to: de.meters).map(\.id) == ["DE"])
        #expect(Milestone.newlyCrossed(from: de.meters, to: de.meters + 1).isEmpty)
    }
    @Test func nextMilestone() {
        #expect(Milestone.next(after: 0)?.id == "DE")
        #expect(Milestone.next(after: 1e12) == nil)
    }
}

@Suite struct StateTests {
    @Test func advanceIssuesCertificatesOnce() {
        var s = OdometerState()
        let ri = Milestone.stateLines[1].meters
        let fresh = s.advance(to: ri + 1)
        #expect(fresh.map(\.milestoneID) == ["DE", "RI"])
        #expect(s.advance(to: ri + 2).isEmpty)
        #expect(s.certificates.count == 2)
    }
    @Test func roundTripsThroughJSON() throws {
        var s = OdometerState(totalMeters: 12.5)
        s.advance(to: 100_000)
        let data = try JSONEncoder().encode(s)
        #expect(try JSONDecoder().decode(OdometerState.self, from: data) == s)
    }
}
