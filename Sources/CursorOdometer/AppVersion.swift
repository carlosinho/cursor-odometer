/// Single source of truth for the app version. `scripts/bundle.sh` reads this file
/// to fill `CFBundleShortVersionString`, so the constant must stay on one line.
enum AppVersion {
    static let short = "0.1.0"
}
