# Cursor Odometer

A macOS menu bar app that tracks how far your mouse cursor has traveled across the glass of your
displays, in standard units and less serious ones like football fields, blue whales, and Titanics.
As the total passes real-world distances it issues certificates: your first marathon, the height
of Everest, the edge of space, crossing Delaware or Germany, and eventually the Moon.

## Certificates

Milestones come in four categories. The popover always shows the next one in each, with a
progress bar, so there is something close from the first hour on.

| Category | Examples |
|---|---|
| Sport | football field, first mile or kilometer, half marathon, marathon, English Channel, Ironman, Tour de France |
| Landmarks | Eiffel Tower, Burj Khalifa, Golden Gate Bridge, Everest, Manhattan, Lake Geneva, Panama Canal, Great Wall, the Equator |
| Space | Kármán line, ISS altitude, the Moon |
| Region | US state crossings (US units) or European country crossings (metric) |

All distances are approximate and live in one table in `Sources/OdometerCore/Milestones.swift`.

## Units

Settings (in the popover) offers two measurement systems:

| | US | Metric |
|---|---|---|
| Standard units | miles, feet | kilometers, meters |
| Football field | 100 yards (91.44 m) | 105 m pitch |
| Region certificates | crossing US states, Delaware to Texas | crossing European countries, Liechtenstein to Spain |

Settings also has a checklist of custom units, from bananas to light-seconds. The defaults are
football fields, blue whales, Boeing 747s, Titanics, Eiffel Towers, Golden Gate Bridges, and
marathons.

Switching systems keeps the total and backfills certificates for milestones already passed in the
new system. Certificates earned in the other system are kept but hidden until you switch back.

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
