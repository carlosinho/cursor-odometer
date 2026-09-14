import SwiftUI
import OdometerCore

@main
struct CursorOdometerApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        MenuBarExtra {
            OdometerView(tracker: delegate.tracker)
        } label: {
            MenuBarLabel(tracker: delegate.tracker)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Separate view so the menu bar title re-renders when the tracker publishes.
private struct MenuBarLabel: View {
    @ObservedObject var tracker: Tracker
    var body: some View {
        Label(tracker.state.system.primaryUnit.format(meters: tracker.state.totalMeters), systemImage: "cursorarrow.motionlines")
    }
}

/// Owns the tracker so tracking starts at launch, not when the popover first opens.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let tracker = Tracker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        tracker.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tracker.stop()
    }
}
