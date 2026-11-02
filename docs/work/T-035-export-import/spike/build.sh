#!/bin/zsh
# Builds the throwaway T-035 spike as a sandboxed LSUIElement app: ./build.sh <output dir>
set -e
here=${0:A:h}
out=${1:-$here/build}
app=$out/DialogSpike.app
rm -rf $app; mkdir -p $app/Contents/MacOS
cat > $app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.muchfiner.HabitCal.dialogspike</string>
  <key>CFBundleExecutable</key><string>DialogSpike</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
cat > $out/spike.entitlements <<'ENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.app-sandbox</key><true/>
  <key>com.apple.security.files.user-selected.read-write</key><true/>
</dict></plist>
ENT
swiftc -O -target arm64-apple-macos15 $here/Spike.swift -o $app/Contents/MacOS/DialogSpike
codesign --force --sign - --entitlements $out/spike.entitlements $app
swiftc -O $here/Check.swift -o $out/check
echo $app
