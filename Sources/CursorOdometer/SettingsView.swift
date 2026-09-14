import SwiftUI
import OdometerCore

struct SettingsView: View {
    @ObservedObject var tracker: Tracker
    @AppStorage("showDebugControls") private var showDebug = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.headline)
            Picker("Units", selection: Binding(
                get: { tracker.state.system },
                set: { tracker.setSystem($0) }
            )) {
                ForEach(MeasurementSystem.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(description).font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Custom units").font(.caption).foregroundStyle(.secondary)
            ForEach(DistanceUnit.customCatalog(for: tracker.state.system)) { unit in
                Toggle(isOn: Binding(
                    get: { tracker.state.isCustomUnitEnabled(unit.id) },
                    set: { tracker.setCustomUnit(unit.id, enabled: $0) }
                )) {
                    HStack {
                        Text(unit.plural.prefix(1).uppercased() + unit.plural.dropFirst())
                        Spacer()
                        Text(DistanceUnit.meters.format(meters: unit.metersPerUnit)).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .toggleStyle(.checkbox)
                .font(.callout)
            }
            Divider()
            Toggle("Show debug controls", isOn: $showDebug)
            Text("Adds buttons to the main page that simulate distance, so certificates can be tested without weeks of mousing.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            HStack {
                Button("Reset odometer…") { confirmReset() }.controlSize(.small)
                Text("Erases the total and all certificates. Keeps these settings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Text("Cursor Odometer \(AppVersion.short)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(width: 300, alignment: .leading)
    }

    private func confirmReset() {
        let alert = NSAlert()
        alert.messageText = "Reset the odometer?"
        alert.informativeText = "Total distance and all certificates will be erased."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn { tracker.reset() }
    }

    private var description: String {
        switch tracker.state.system {
        case .us: return "Miles and feet, 100-yard football fields, and certificates for crossing US states."
        case .metric: return "Kilometers and meters, 105-meter football fields, and certificates for crossing European countries."
        }
    }
}
