import SwiftUI
import OdometerCore

struct CertificateView: View {
    let certificate: Certificate
    let system: MeasurementSystem
    private var unit: DistanceUnit { certificate.milestone?.unit ?? system.primaryUnit }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "rosette")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
                .padding(.bottom, 4)

            Text("Certificate of Cursor Travel")
                .font(.subheadline.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.bottom, 4)

            Text("This certifies that the cursor of")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(NSFullUserName())
                .font(.title2.bold())
            Text("has traveled a distance equivalent to")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(certificate.milestone?.detail ?? certificate.milestoneID)
                .font(.title3.bold())
            Text("\(unit.format(meters: certificate.milestone?.meters ?? 0)) of on-screen cursor movement")
                .font(.callout)

            Divider().padding(.vertical, 6)

            Text("Total at crossing: \(unit.format(meters: certificate.totalMetersAtCrossing))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Issued \(certificate.earnedAt.formatted(date: .long, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.yellow, lineWidth: 3)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(width: 300)
    }
}
