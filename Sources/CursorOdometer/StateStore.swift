import Foundation
import OdometerCore

/// Persists OdometerState as JSON in Application Support using atomic writes.
struct StateStore {
    let url: URL

    static func `default`() -> StateStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("CursorOdometer", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return StateStore(url: dir.appendingPathComponent("state.json"))
    }

    func load() -> OdometerState {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(OdometerState.self, from: data) else { return OdometerState() }
        return state
    }

    func save(_ state: OdometerState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
