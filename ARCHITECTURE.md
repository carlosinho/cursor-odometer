# Architecture

This document describes how Cursor Odometer is built and why. See `README.md` for what it does and how to run it.

## Design philosophy

The app is split into a pure library and a thin shell.

- `OdometerCore` contains every rule that could be wrong: unit conversion, distance accumulation, milestone crossing, certificate issuing, system switching, persistence format. It imports only Foundation and has no AppKit, SwiftUI, or file access. Everything in it is a value type and is unit tested.
- `CursorOdometer` is the AppKit and SwiftUI shell: one event monitor, one timer, one file, three popover pages. It contains no distance math.

The build is SwiftPM only. There is no Xcode project, no storyboard, no asset catalog. The `.app` bundle is assembled by a shell script because a bundle is the only way to get `LSUIElement` (no Dock icon) and a stable bundle identifier, which macOS uses to remember the menu bar item's position.

## Key invariants

- Distance is stored in meters, always. Units, systems, and milestones are views over one `Double`.
- Every certificate is issued at most once per milestone id, across system switches and for the lifetime of the state file. `OdometerState.issue` filters against the set of already earned ids.
- Milestone ids are namespaced: `sport.*`, `landmark.*`, `space.*`, `state.XX`, `country.XX`. `Milestone.find` accepts bare state codes as a fallback because the first version of the state file used them.
- The football field unit has id `football` in both systems with different lengths. Custom unit selection is stored by id, so a user who enabled football fields keeps them when switching systems and gets the other length.
- `customUnitIDs == nil` means "use the defaults". It becomes a concrete array on the first change the user makes, and from then on the defaults no longer apply.
- Tracking starts in `applicationDidFinishLaunching`, not when the popover opens. The `AppDelegate` owns the `Tracker` for that reason.
- The event handler does no work beyond recording one point. All derived state is computed on a one-second timer.

## Data flow

```
NSEvent global monitor (mouseMoved, *MouseDragged)
  -> Tracker.sample()            reads NSEvent.mouseLocation, finds the screen, looks up calibration
  -> DistanceAccumulator.record  applies rejection rules, adds meters
                                 (no UI, no disk, no allocation beyond the Task hop)

Timer, every 1 s
  -> Tracker.publish()
       if accumulator total == state total: nothing
       else state.advance(to: total)          issues certificates for milestones in (old, new]
            newCertificate = first fresh one  drives the popover banner
            save if moved > 0.5 m since last save, or any certificate was issued

Quit
  -> Tracker.stop()               removes monitor, final publish, unconditional save
```

Screen calibration is computed once at start and again on `NSApplication.didChangeScreenParametersNotification`, and cached by display id. `sample()` does a dictionary lookup, not a system call, per event.

Simulated distance from the debug buttons goes through `DistanceAccumulator.add` and then the same `publish()` path, so it is indistinguishable from real movement downstream.

## Distance measurement

`NSEvent.mouseLocation` is in global screen points. For each display, `CGDisplayScreenSize` returns its physical size in millimeters as reported by the display's EDID. Points per millimeter is display width in points divided by physical width in millimeters. Retina scale factors do not enter into it because both inputs are in points.

Rejection rules, all in `DistanceAccumulator.record`:

| Rule | Reason |
|---|---|
| First sample after start or reset counts nothing | There is no previous point |
| Sample on a different display than the previous sample counts nothing, but becomes the new anchor | Cross-display jumps are not physical movement, and the two displays may have different ratios |
| Move longer than `teleportFraction` (0.5) of the display diagonal counts nothing, but becomes the new anchor | Sleep and wake, screen sharing, hot corners, and cursor warping produce single huge deltas |
| Display with no valid physical size counts nothing | No ratio, no meters; the tracker also flags it for the UI |

The accumulator sums straight-line distance between consecutive events. Events arrive at the mouse's report rate, typically 125 to 1000 Hz, so the polyline approximation is close. Movement over the app's own popover is invisible to the global monitor by macOS design and is not counted.

## Persistence

One file: `~/Library/Application Support/CursorOdometer/state.json`, written with `Data.write(options: .atomic)` so a crash mid-write leaves the previous file intact.

`OdometerState` is the entire document:

| Field | Type | Purpose |
|---|---|---|
| `totalMeters` | Double | The odometer |
| `startedAt` | Date | Shown as "since" on the main page; reset by Reset |
| `certificates` | [Certificate] | Every certificate ever issued, all systems, in issue order |
| `system` | MeasurementSystem | `us` or `metric`; missing in old files and decoded as `us` |
| `customUnitIDs` | [String]? | Enabled custom unit ids; missing or null means defaults |

`Certificate` holds `milestoneID`, `earnedAt`, and `totalMetersAtCrossing`. It does not store the milestone's title or distance; those are looked up from the tables at display time so that edits to the tables apply retroactively.

A custom `init(from:)` on `OdometerState` makes the two preference fields optional for backward compatibility. Encoding uses the synthesized encoder.

Write policy: at most once per second, only when the total moved more than 0.5 meters since the last write or a certificate was issued, plus unconditionally on quit, reset, and every preference change. Losing at most one second of movement on a crash is acceptable; writing on every mouse event is not.

The debug toggle is the one thing not in the file. It is a SwiftUI `@AppStorage("showDebugControls")` in UserDefaults because it is a UI preference of no consequence to the data.

## State transitions

`advance(to:)` moves the total forward and issues certificates for every active milestone with distance in `(old, new]`. The interval is half open so a total that lands exactly on a milestone issues it and the next tick does not issue it again.

`setSystem(_:)` changes the system and then issues certificates for every milestone of the new system in `(0, total]` that is not already earned. This backfill is deliberate: without it a user who switches after 100 km would never receive Liechtenstein, because `advance` only looks at the interval covered by new movement. The backfill sets `earnedAt` to the switch time, and the tracker does not show the banner for it.

`certificatesForCurrentSystem` filters the full list to milestones in the active system's table. Universal milestones (Sport, Landmarks, Space) are in both tables and therefore always visible. Region and the two early Sport milestones are system specific and hidden when the other system is active.

Reset constructs a fresh `OdometerState` carrying over only `system` and `customUnitIDs`.

Popover navigation is a `Page` enum (`main`, `settings`, `certificate(Certificate)`) held in `@State` on `OdometerView`. SwiftUI's `NavigationStack` was tried first and lays out pushed views as empty inside a `MenuBarExtra` window, so it is not used.

## Milestone model

`Milestone` is a value with `id`, `category`, `title`, `detail`, and `meters`. Tables are static arrays:

- `universal`: Sport, Landmarks, and Space entries active in both systems.
- `usEarly` and `metricEarly`: the football field and first mile or first kilometer, one pair per system.
- `stateLines` and `countries`: the Region ladders.

`MeasurementSystem.milestones` concatenates the right three. `nextPerCategory` returns the closest unearned-by-distance milestone per category in fixed category order and drives the "Next up" section. A category with nothing left simply disappears from the list.

`Milestone.unit` returns miles for `state.*`, kilometers for `country.*`, and nil otherwise. The certificate page uses that unit when present and the active system's primary unit when nil, so a Delaware certificate always reads in miles even when viewed under metric.

## Concurrency

`Tracker` and `AppDelegate` are `@MainActor`. The global monitor callback and the timer callback both hop to the main actor with `Task { @MainActor in ... }` before touching state. The package is compiled in Swift 5 language mode (tools version 5.9), so this is a convention, not a compiler guarantee, but every mutation path goes through those two entry points, `stop()`, or the SwiftUI bindings, all on the main thread.

The per-event `Task` hop allocates a task for every mouse event. At 1000 Hz this has not shown measurable cost, and the alternative, calling into the accumulator directly from the monitor's callback thread, would require making the accumulator thread safe.

## Failure handling

- Missing or corrupt state file: `StateStore.load` returns a fresh `OdometerState`. The corrupt file is overwritten on the next save. There is no backup.
- Encoding failure or write failure: silently ignored; the in-memory state continues and the next save retries.
- Display disconnected while it is the anchor: the next sample is on another display and is discarded by the screen-change rule.
- Display reports a physical size of zero or NaN: `pointsPerMillimeter` returns nil, the calibration is marked unsupported, movement is ignored, the UI shows the warning.
- Display reports a wrong physical size: not detected. The total will be scaled wrong for that display. A manual override was considered and not built.
- Two milestones crossed in one tick: all are issued; the banner shows only the first. The others are visible in the certificate list.
- App killed without `applicationWillTerminate`: up to one second plus up to 0.5 meters of movement is lost.

## Security and privacy

The app reads cursor position and nothing else. It has no network code, no entitlements, no sandbox, and requests no permissions. It never sees keyboard events, window contents, or which app the cursor is over. The state file contains distance, dates, and preferences. The certificate page displays `NSFullUserName()` at render time and does not store it.

The bundle is ad-hoc signed by `scripts/bundle.sh`. That is enough for a locally built app to launch. A copy downloaded from elsewhere would be quarantined by Gatekeeper; distribution was not a goal.

## Scalability limits

There is one user, one machine, one file. The certificates array grows by at most the number of milestones, currently 45 across all tables. Nothing here needs to scale, and nothing is designed to.

The one real ceiling is the menu bar itself: on notched MacBooks with a full status area, macOS hides the newest status item under the notch. The app cannot influence this; only the user can, by freeing space and dragging the item.

## Testing

`Tests/OdometerCoreTests` covers `OdometerCore` only, with Swift Testing. Suites: calibration math and unsupported display detection; accumulator rules (first sample, straight line, screen change, teleport, unsupported screen, add and reset); unit conversion and locale-pinned formatting; milestone table integrity (unique ids, correct categories, next-per-category order, legacy id lookup); measurement system differences; custom unit catalog and selection; state advance, backfill on switch, and JSON round trip including decoding a file without the preference fields.

`Tracker`, `StateStore`, and the views are not unit tested. They are exercised by running the app.

`scripts/test.sh` exists because the Command Line Tools toolchain ships `Testing.framework` outside the SDK and without its Foundation cross-import overlay. The script adds the framework search path and rpath and disables cross-import overlays. Putting the same flags in `Package.swift` as `unsafeFlags` builds but does not run the tests under this toolchain, so the wrapper is the working solution.

## Maintenance notes

- Adding a milestone: one line in the appropriate table in `Milestones.swift`, with a unique namespaced id. Users who have already passed it get the certificate on their next tick that moves the total, or on their next system switch. Tables are not required to be sorted; queries sort.
- Adding a custom unit: one static in `Units.swift` and one entry in `customCatalog`. To make it a default, add its id to `defaultCustomIDs`; this affects only users who have never changed their selection.
- Renaming a milestone id breaks existing certificates for it unless a fallback is added to `Milestone.find`.
- Number formatting uses the current locale. Tests pass an explicit `en_US` locale.
