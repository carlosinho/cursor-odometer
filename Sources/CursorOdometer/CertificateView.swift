import SwiftUI
import OdometerCore

struct CertificateView: View {
    let certificate: Certificate

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rosette").font(.system(size: 40)).foregroundStyle(.yellow)
            Text("Certificate of Cursor Travel").font(.headline).textCase(.uppercase).tracking(2)
            Text("This certifies that the cursor of").font(.callout).foregroundStyle(.secondary)
            Text(NSFullUserName()).font(.title2.bold())
            Text("has traveled a distance equivalent to").font(.callout).foregroundStyle(.secondary)
            Text(certificate.milestone?.detail ?? certificate.milestoneID).font(.title3.bold()).multilineTextAlignment(.center)
            Text("\(DistanceUnit.miles.format(meters: certificate.milestone?.meters ?? 0)) of on-screen cursor movement")
                .font(.callout)
            Divider()
            Text("Total at crossing: \(DistanceUnit.miles.format(meters: certificate.totalMetersAtCrossing))")
                .font(.caption).foregroundStyle(.secondary)
            Text("Issued \(certificate.earnedAt.formatted(date: .long, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(.yellow, lineWidth: 3).padding(6))
    }
}
