#!/usr/bin/env bash
# Called by CI right after `flutter create` to configure the generated Android
# project. Idempotent: every step checks before patching.
#
# It does three things:
#   1. Adds CAMERA + INTERNET permissions and a camera uses-feature entry
#      (the Flutter template only ships INTERNET in the debug/profile manifests).
#   2. Allows plain-HTTP traffic so the app can reach the StyleSnap bridge on
#      the local network (http://<host>:8600). Remove for HTTPS-only deployments.
#   3. Sets a human-friendly app label ("StyleSnap" instead of "stylesnap").

set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
test -f "$MANIFEST"

# 1) Runtime permissions + optional camera hardware feature
if ! grep -q "android.permission.CAMERA" "$MANIFEST"; then
  sed -i 's|<application|<uses-permission android:name="android.permission.CAMERA"/><uses-permission android:name="android.permission.INTERNET"/><uses-feature android:name="android.hardware.camera" android:required="false"/><application|' "$MANIFEST"
fi

# 2) Allow cleartext HTTP to the bridge on the LAN
if ! grep -q "usesCleartextTraffic" "$MANIFEST"; then
  sed -i 's|<application |<application android:usesCleartextTraffic="true" |' "$MANIFEST"
fi

# 3) App label shown on the launcher
sed -i 's|android:label="stylesnap"|android:label="StyleSnap"|' "$MANIFEST"

echo "---- android/app/src/main/AndroidManifest.xml ----"
cat "$MANIFEST"
