# Cursor Odometer

A macOS menu bar app that tracks how far your mouse cursor has traveled across the glass of your
displays, in miles, kilometers, meters, feet, and less serious units like football fields.
When your cursor has covered a distance equal to crossing a US state, it issues a certificate.

This is a proof of concept meant to be built and run locally. It is not signed, notarized, or
distributed through the App Store.

## How it measures distance

- A global mouse-moved monitor receives every cursor movement. No Accessibility or Input Monitoring
  permission is required for mouse events.
- Each display's physical width in millimeters (as reported by the display) and its width in points
  give a points-per-millimeter ratio. Movement is converted with that ratio, so the result is the
  distance the cursor traveled on the screen surface.
- Displays that do not report a physical size are unsupported. Movement on them is ignored and the
  popover shows a warning while the cursor is on one.
- Jumps between displays and single moves longer than half a screen diagonal (sleep and wake,
  screen sharing, hot corners) are treated as teleports and not counted.

The running total is saved as JSON in `~/Library/Application Support/CursorOdometer/state.json`.

## Requirements

- macOS 13 or later
- Swift 6 Command Line Tools (`xcode-select --install`). Full Xcode is not needed.

## Build and run

```sh
scripts/bundle.sh --open
```

That builds a release binary, wraps it in `build/CursorOdometer.app`, ad-hoc signs it, and launches it.
The app lives in the menu bar only. Click the cursor icon to see totals, the next state line, earned
certificates, and reset or quit.

For development you can also run the bare executable without a bundle:

```sh
swift run CursorOdometer
```

## Tests

```sh
scripts/test.sh
```

The core logic (calibration, accumulation, units, milestones, state) lives in the `OdometerCore`
library and is covered by tests. The Command Line Tools toolchain does not ship XCTest and keeps
the Swift Testing framework outside the SDK, so the script passes the search paths that plain
`swift test` lacks. With full Xcode installed, `swift test` works directly.

## Testing certificates without waiting months

Crossing even Delaware takes about 30 miles of cursor travel. The popover has a "Debug" link that
reveals buttons adding 1, 10, or 100 simulated miles so you can see certificates issue.

## Project layout

```
Sources/OdometerCore/      pure logic, no AppKit
Sources/CursorOdometer/    menu bar app (SwiftUI + a small AppKit tracker)
Tests/OdometerCoreTests/   Swift Testing suites for OdometerCore
scripts/bundle.sh          assembles the .app
scripts/test.sh            runs the tests under Command Line Tools
```

## License

MIT. See [LICENSE](LICENSE).
