import SwiftUI
import OdometerCore

struct OdometerView: View {
    @ObservedObject var tracker: Tracker
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                unitList(title: "Standard", units: DistanceUnit.standard)
                unitList(title: "Custom", units: DistanceUnit.custom)
                Divider()
                milestones
                Divider()
                footer
            }
            .padding(14)
            .frame(width: 300)
            .navigationDestination(for: Certificate.self) { CertificateView(certificate: $0) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DistanceUnit.miles.format(meters: tracker.state.totalMeters))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("since \(tracker.state.startedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(.secondary)
            if !tracker.currentScreenSupported {
                Label("This display doesn't report its size. Movement here isn't counted.", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private func unitList(title: String, units: [DistanceUnit]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            ForEach(units) { unit in
                HStack {
                    Text(unit.plural.capitalized)
                    Spacer()
                    Text(unit.format(meters: tracker.state.totalMeters)).monospacedDigit()
                }
                .font(.callout)
            }
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("State lines").font(.caption).foregroundStyle(.secondary)
            if let next = Milestone.next(after: tracker.state.totalMeters) {
                let remaining = next.meters - tracker.state.totalMeters
                HStack {
                    Text("Next: \(next.title)")
                    Spacer()
                    Text("\(DistanceUnit.miles.format(meters: remaining)) to go").foregroundStyle(.secondary)
                }
                .font(.callout)
                ProgressView(value: tracker.state.totalMeters, total: next.meters)
            } else {
                Text("You've crossed them all.").font(.callout)
            }
            ForEach(tracker.state.certificates.reversed()) { cert in
                NavigationLink(value: cert) {
                    HStack {
                        Image(systemName: "rosette")
                        Text(cert.milestone?.title ?? cert.milestoneID)
                        Spacer()
                        Text(cert.earnedAt.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
                .buttonStyle(.plain)
            }
            if let fresh = tracker.newCertificate {
                NavigationLink(value: fresh) {
                    Label("New certificate: \(fresh.milestone?.title ?? fresh.milestoneID)!", systemImage: "sparkles")
                        .font(.callout.bold())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { tracker.dismissNewCertificate() })
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button("Reset…") { confirmReset() }
                Spacer()
                Button("Debug") { showDebug.toggle() }.buttonStyle(.link).font(.caption)
                Button("Quit") { NSApp.terminate(nil) }
            }
            .controlSize(.small)
            if showDebug {
                HStack {
                    Button("+1 mile") { tracker.simulate(meters: DistanceUnit.miles.metersPerUnit) }
                    Button("+10 miles") { tracker.simulate(meters: 10 * DistanceUnit.miles.metersPerUnit) }
                    Button("+100 miles") { tracker.simulate(meters: 100 * DistanceUnit.miles.metersPerUnit) }
                }
                .controlSize(.small)
            }
        }
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
}

extension Certificate: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(milestoneID) }
}
