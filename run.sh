#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Building Stacker..."
cd "$DIR"
swift build -c release
mkdir -p "$DIR/Stacker.app/Contents/MacOS"
cp "$DIR/.build/release/Stacker" "$DIR/Stacker.app/Contents/MacOS/Stacker"
chmod +x "$DIR/Stacker.app/Contents/MacOS/Stacker"

echo "Launching Stacker..."
open "$DIR/Stacker.app"
