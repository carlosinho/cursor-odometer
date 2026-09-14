import AppKit
import Combine
import OdometerCore

/// Owns the global mouse monitor, the accumulator, and persistence.
/// The event handler only records a point; the published UI state refreshes on a slow timer.
@MainActor
final class Tracker: ObservableObject {
    @Published private(set) var state: OdometerState
    @Published private(set) var currentScreenSupported = true
    @Published private(set) var newCertificate: Certificate?

    private var accumulator: DistanceAccumulator
    private let store: StateStore
    private var calibrations: [UInt32: ScreenCalibration] = [:]
    private var monitor: Any?
    private var refreshTimer: Timer?
    private var lastSavedMeters: Double

    init(store: StateStore = .default()) {
        self.store = store
        let loaded = store.load()
        state = loaded
        accumulator = DistanceAccumulator(totalMeters: loaded.totalMeters)
        lastSavedMeters = loaded.totalMeters
    }

    func start() {
        refreshCalibrations()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshCalibrations() }
        }
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        refreshTimer?.invalidate()
        publish()
        store.save(state)
    }

    /// Adds distance without moving the mouse. Used to exercise certificates.
    func simulate(meters: Double) {
        accumulator.add(meters: meters)
        publish()
    }

    func reset() {
        accumulator.reset()
        state = OdometerState(system: state.system, customUnitIDs: state.customUnitIDs)
        newCertificate = nil
        store.save(state)
        lastSavedMeters = 0
    }

    func dismissNewCertificate() { newCertificate = nil }

    func setCustomUnit(_ id: String, enabled: Bool) {
        state.setCustomUnit(id, enabled: enabled)
        store.save(state)
    }

    func setSystem(_ system: MeasurementSystem) {
        guard system != state.system else { return }
        state.setSystem(system)
        store.save(state)
    }

    // MARK: - Private

    private func sample() {
        let location = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }),
              let calibration = calibrations[screen.displayID] else { return }
        if calibration.isSupported != currentScreenSupported { currentScreenSupported = calibration.isSupported }
        accumulator.record(CursorPoint(x: location.x, y: location.y), on: calibration)
    }

    private func publish() {
        let total = accumulator.totalMeters
        guard total != state.totalMeters else { return }
        let fresh = state.advance(to: total)
        if let first = fresh.first { newCertificate = first }
        if abs(total - lastSavedMeters) > 0.5 || !fresh.isEmpty {
            store.save(state)
            lastSavedMeters = total
        }
    }

    private func refreshCalibrations() {
        calibrations = Dictionary(uniqueKeysWithValues: NSScreen.screens.map { screen in
            let id = screen.displayID
            let mm = CGDisplayScreenSize(id)
            let ppmm = pointsPerMillimeter(frameWidthPoints: screen.frame.width, physicalWidthMillimeters: mm.width)
            return (id, ScreenCalibration(id: id, widthPoints: screen.frame.width,
                                          heightPoints: screen.frame.height, pointsPerMillimeter: ppmm))
        })
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
}
