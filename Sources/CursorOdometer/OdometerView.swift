import SwiftUI
import OdometerCore

/// Which page the popover shows. A plain switch is used instead of NavigationStack,
/// which does not lay out pushed views inside a MenuBarExtra window.
enum Page: Equatable {
    case main
    case settings
    case certificate(Certificate)
}

struct OdometerView: View {
    @ObservedObject var tracker: Tracker
    @AppStorage("showDebugControls") private var showDebug = false
    @State private var page: Page = .main

    private var system: MeasurementSystem { tracker.state.system }
    private var total: Double { tracker.state.totalMeters }

    var body: some View {
        Group {
            switch page {
            case .main:
                mainPage
            case .settings:
                subpage { SettingsView(tracker: tracker) }
            case .certificate(let cert):
                subpage { CertificateView(certificate: cert, system: system) }
            }
        }
        .frame(width: 300)
    }

    private var mainPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            unitList(title: "Standard", units: system.standardUnits)
            if !tracker.state.customUnits.isEmpty {
                unitList(title: "Custom", units: tracker.state.customUnits)
            }
            Divider()
            milestones
            Divider()
            footer
        }
        .padding(14)
    }

    private func subpage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { page = .main } label: { Label("Back", systemImage: "chevron.left") }
                .buttonStyle(.link)
                .padding(.horizontal, 14)
                .padding(.top, 10)
            content()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(system.primaryUnit.format(meters: total))
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
                    Text(unit.format(meters: total)).monospacedDigit()
                }
                .font(.callout)
            }
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next up").font(.caption).foregroundStyle(.secondary)
            ForEach(Milestone.nextPerCategory(after: total, in: system.milestones)) { next in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(system.title(for: next.category)).foregroundStyle(.secondary)
                        Text(next.title)
                        Spacer()
                        Text("\(system.primaryUnit.format(meters: next.meters - total)) to go").foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    ProgressView(value: min(total, next.meters), total: next.meters)
                }
            }
            if let fresh = tracker.newCertificate {
                Button {
                    tracker.dismissNewCertificate()
                    page = .certificate(fresh)
                } label: {
                    Label("New certificate: \(fresh.milestone?.title ?? fresh.milestoneID)!", systemImage: "sparkles")
                        .font(.callout.bold())
                }
                .buttonStyle(.plain)
            }
            certificates
        }
    }

    @ViewBuilder
    private var certificates: some View {
        let earned = tracker.state.certificatesForCurrentSystem
        if !earned.isEmpty {
            Divider()
            Text("Certificates").font(.caption).foregroundStyle(.secondary)
            ForEach(MilestoneCategory.allCases) { category in
                let rows = earned.filter { $0.milestone?.category == category }.reversed()
                if !rows.isEmpty {
                    Text(system.title(for: category)).font(.caption2).foregroundStyle(.tertiary)
                    ForEach(rows) { cert in
                        Button { page = .certificate(cert) } label: {
                            HStack {
                                Image(systemName: "rosette")
                                Text(cert.milestone?.title ?? cert.milestoneID)
                                Spacer()
                                Text(cert.earnedAt.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                            }
                            .font(.callout)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button { page = .settings } label: { Label("Settings", systemImage: "gearshape") }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .controlSize(.small)
            if showDebug {
                let unit = system.primaryUnit
                HStack {
                    Text("Debug").font(.caption).foregroundStyle(.secondary)
                    ForEach([1.0, 10, 100], id: \.self) { n in
                        Button("+\(Int(n)) \(unit.symbol ?? unit.plural)") { tracker.simulate(meters: n * unit.metersPerUnit) }
                    }
                }
                .controlSize(.small)
            }
        }
    }
}
