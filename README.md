# Cursor Odometer

A macOS menu bar app that measures how far your mouse cursor has physically traveled across the glass of your displays. It shows the total in miles or kilometers, in silly units like blue whales and Titanics, and issues certificates when the total passes real-world distances: your first marathon, the height of Everest, the edge of space, the width of Delaware or Germany, and eventually the Moon.

MIT licensed.

## Why

Nobody knows how far their cursor goes in a year. And I am sure everybody wants to know it badly. So, now you can.

## What it does

- Counts cursor movement in physical units by converting screen points to millimeters using each display's reported physical size.
- Shows the running total in the menu bar popover, in standard units and in a user-chosen set of custom units.
- Issues a certificate every time the total crosses a milestone, in four categories: Sport, Landmarks, Space, and Region.
- Persists everything between launches in a single JSON file.

The menu bar item itself shows the cursor icon. Everything else lives in the popover.

## User flows

**Main page.** Click the cursor icon in the menu bar. The popover shows the total in the primary unit with the date tracking started, the standard units, the enabled custom units, a "Next up" list with the closest upcoming milestone in each category and a progress bar, a banner when a new certificate was just issued, and earned certificates grouped by category. The footer has Settings and Quit.

**Certificate page.** Click a certificate row or the "New certificate" banner. The page shows your macOS full name, the crossing, its distance, the total at the moment of crossing, and the issue date. Certificates exist only inside the app; nothing is exported.

**Settings page.** Opened from the footer.

- Units: US or Metric. This switches the primary unit (miles or kilometers), the standard unit list (miles and feet, or kilometers and meters), the football field length (100 yards or 105 meters, both called a football field), and the Region milestone ladder (US states or European countries).
- Custom units: a checklist of 18 units from bananas to light-seconds. Defaults are football fields, blue whales, Boeing 747s, Titanics, Eiffel Towers, Golden Gate Bridges, and marathons.
- Show debug controls: adds +1, +10, and +100 buttons in the primary unit to the main page. They add real distance to the total, which is the only practical way to see a certificate without weeks of mousing.

**Reset.** At the bottom of Settings. Asks for confirmation, then zeroes the total, clears all certificates, and restarts the "since" date. The unit system and custom unit selection are kept.

**Switching systems.** The total never changes. Milestones in the newly selected system that the total has already passed get certificates immediately, without the banner. Certificates from the other system stay saved and reappear when you switch back.

## Milestones

| Category | Entries |
|---|---|
| Sport | football field, first mile (US) or first kilometer (metric), half marathon, English Channel, first marathon, Ironman, Tour de France |
| Landmarks | Eiffel Tower, Burj Khalifa, Golden Gate Bridge, Mount Everest, Manhattan, Lake Geneva, Panama Canal, Great Wall of China, around the Equator |
| Space | Kármán line, ISS altitude, the Moon |
| Region (US) | Delaware, Rhode Island, Connecticut, New Jersey, Vermont, Massachusetts, West Virginia, Ohio, Colorado, Montana, Texas |
| Region (metric) | Liechtenstein, Luxembourg, Belgium, Netherlands, Switzerland, Austria, Denmark, Germany, Poland, France, Spain |

All distances are approximate and defined in one place, `Sources/OdometerCore/Milestones.swift`. Region entries are the shortest straight-line crossing of each place.

## What counts as distance

- Only movement on a display that reports its physical size. Displays that report none are unsupported; movement on them is ignored and the main page shows a warning while the cursor is there.
- Only movement within one display. A jump from one display to another is not counted.
- Only moves shorter than half the display's diagonal. Anything longer is treated as a teleport (sleep and wake, screen sharing, hot corners, cursor warping) and dropped.
- Not movement over the app's own popover. macOS global event monitors do not deliver events aimed at the app itself.

No Accessibility or Input Monitoring permission is needed. Mouse events, unlike keyboard events, are available to global monitors without one.

## Requirements

- macOS 13 Ventura or later. Tested on macOS 15.
- Swift 6 Command Line Tools (`xcode-select --install`). Full Xcode is not required and was not used.

## Build and run

```sh
scripts/bundle.sh --open
```

This builds a release binary with SwiftPM, wraps it in `build/CursorOdometer.app` with a generated Info.plist and icon, signs it ad hoc, and launches it. Omit `--open` to only build. The app has no Dock icon and no windows other than the popover; quit it from the popover footer.

For a quick development run without a bundle:

```sh
swift run CursorOdometer
```

Running unbundled works for tracking but has no bundle identifier, so macOS treats it as a different app for menu bar item positioning.

## Tests

```sh
scripts/test.sh
```

Runs the Swift Testing suites for the core library. The wrapper exists because the Command Line Tools toolchain ships no XCTest and keeps the Swift Testing framework outside the SDK; the script passes the missing search paths. With Xcode installed, plain `swift test` also works.

## Configuration and data

There are no environment variables and no config files.

| Item | Location |
|---|---|
| All tracked state and preferences | `~/Library/Application Support/CursorOdometer/state.json` |
| Debug controls toggle | UserDefaults key `showDebugControls` in domain `com.local.cursor-odometer` |
| Bundle identifier | `com.local.cursor-odometer`, set in `scripts/bundle.sh` |
| App version | `Sources/CursorOdometer/AppVersion.swift`; shown in Settings and copied into Info.plist by `scripts/bundle.sh` |
| App icon | `Resources/app-icon.png`, converted to `.icns` by `scripts/bundle.sh` |

Delete the JSON file to start over completely, including preferences. Reset inside the app keeps preferences.

## Project structure

```
Package.swift                          SwiftPM manifest, tools version 5.9, macOS 13 minimum
Sources/OdometerCore/                  pure logic, no AppKit or SwiftUI
  Calibration.swift                    points-per-millimeter and per-display calibration
  DistanceAccumulator.swift            turns cursor samples into meters with rejection rules
  Units.swift                          DistanceUnit, standard and custom unit catalog, formatting
  MeasurementSystem.swift              US vs metric: units, milestone set, region title
  Milestones.swift                     milestone categories, all milestone tables, queries
  OdometerState.swift                  persisted state, certificate issuing, system switching
Sources/CursorOdometer/                the app
  CursorOdometerApp.swift              MenuBarExtra scene and AppDelegate
  AppVersion.swift                     the version string, single source of truth
  Tracker.swift                        global mouse monitor, calibration cache, publish and save
  StateStore.swift                     JSON load and atomic save
  OdometerView.swift                   popover: main page and page switching
  SettingsView.swift                   units, custom unit checklist, debug toggle
  CertificateView.swift                certificate page
Tests/OdometerCoreTests/               Swift Testing suites for OdometerCore
Resources/app-icon.png                 source image for the app icon
scripts/bundle.sh                      release build, .app assembly, ad-hoc signing
scripts/test.sh                        swift test with Command Line Tools search paths
```

## Not implemented

These were considered and deliberately left out of the proof of concept: launch at login, user notifications, exporting certificates as files, manual calibration for displays without a reported size, and any form of distribution beyond building from source.

## License

MIT. See `LICENSE`.
