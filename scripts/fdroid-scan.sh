#!/usr/bin/env bash
# Scans the F-Droid-style APK the way F-Droid does. Used by .github/workflows/fdroid-check.yml
set -euo pipefail
APK=khmer_calendar/build/app/outputs/flutter-apk/app-release.apk
test -f "$APK" || { echo "::error::$APK was not produced"; exit 1; }
AAPT=$(ls "$ANDROID_HOME"/build-tools/*/aapt2 | sort -V | tail -1)
BADGING=$("$AAPT" dump badging "$APK")
echo "$BADGING" | head -n 1
DEXDUMP=$(ls "$ANDROID_HOME"/build-tools/*/dexdump | sort -V | tail -1)
rm -rf /tmp/dex && mkdir -p /tmp/dex
unzip -q -o "$APK" 'classes*.dex' -d /tmp/dex
# Same detection as F-Droid's scanner (fdroidserver scanner.get_embedded_classes): any class path
# mentioned anywhere in the dexdump output counts, definitions AND references.
DEXDUMP="$DEXDUMP" python3 - <<'PY'
import glob, os, re, subprocess, sys
BAD = ("com/google/android/gms", "com/google/android/play", "com/google/firebase",
       "com/google/android/datatransport", "com/google/mlkit")
bad = 0
for dex in sorted(glob.glob("/tmp/dex/classes*.dex")):
    out = subprocess.run([os.environ["DEXDUMP"], dex], capture_output=True, text=True).stdout
    for block in re.split(r"\n(?=Class #\d+)", out):
        m = re.search(r"Class descriptor\s*:\s*'L([^;]+);'", block)
        found = sorted({c for c in re.findall(r"[A-Z]+((?:\w+/)+\w+)", block) if c.startswith(BAD)})
        if found:
            bad += 1
            print(f"::error::{m.group(1) if m else '?'} -> {', '.join(found)[:900]}")
if bad:
    print(f"::error::{bad} classes mention Google libraries; F-Droid's scanner would reject this APK")
    sys.exit(1)
print("OK: no Google Play Core / Play Services / Firebase class is mentioned anywhere in the dex")
PY
