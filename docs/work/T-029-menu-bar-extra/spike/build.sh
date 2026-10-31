#!/bin/zsh
# Builds the throwaway T-029 spike into an LSUIElement app bundle: ./build.sh <output dir>
set -e
here=${0:A:h}
out=${1:-$here/build}
app=$out/MBXSpike.app
rm -rf $app
mkdir -p $app/Contents/MacOS
cat > $app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.muchfiner.HabitCal.mbxspike</string>
  <key>CFBundleName</key><string>MBXSpike</string>
  <key>CFBundleExecutable</key><string>MBXSpike</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
</dict></plist>
PLIST
swiftc -parse-as-library -O -target arm64-apple-macos15 $here/Spike.swift -o $app/Contents/MacOS/MBXSpike
echo $app
