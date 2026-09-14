#!/bin/zsh
# Runs the test suite. The Command Line Tools toolchain ships the Swift Testing framework outside
# the SDK and without its Foundation overlay, so it has to be pointed at explicitly.
# With full Xcode installed, plain `swift test` also works.
set -euo pipefail
cd "$(dirname "$0")/.."
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
exec swift test \
  -Xswiftc -F -Xswiftc "$F" \
  -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
  -Xlinker -F -Xlinker "$F" -Xlinker -rpath -Xlinker "$F" "$@"
