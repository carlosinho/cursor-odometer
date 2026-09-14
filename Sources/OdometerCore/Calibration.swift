import Foundation

/// How many screen points correspond to one millimeter of physical glass on a display.
/// Returns nil when the display does not report a usable physical size; such displays are unsupported.
public func pointsPerMillimeter(frameWidthPoints: Double, physicalWidthMillimeters: Double) -> Double? {
    guard frameWidthPoints > 0, physicalWidthMillimeters.isFinite, physicalWidthMillimeters > 0 else { return nil }
    return frameWidthPoints / physicalWidthMillimeters
}

/// A snapshot of one display's geometry, used to convert cursor movement into meters.
public struct ScreenCalibration: Equatable {
    public let id: UInt32
    public let widthPoints: Double
    public let heightPoints: Double
    /// nil means the display is unsupported and movement on it is not counted.
    public let pointsPerMillimeter: Double?

    public init(id: UInt32, widthPoints: Double, heightPoints: Double, pointsPerMillimeter: Double?) {
        self.id = id
        self.widthPoints = widthPoints
        self.heightPoints = heightPoints
        self.pointsPerMillimeter = pointsPerMillimeter
    }

    public var isSupported: Bool { pointsPerMillimeter != nil }

    public var diagonalPoints: Double { (widthPoints * widthPoints + heightPoints * heightPoints).squareRoot() }
}
