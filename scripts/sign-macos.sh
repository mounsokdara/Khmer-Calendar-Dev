#!/usr/bin/env bash
# Sign (and verify) a macOS .app with codesign, using a .p12 from a base64 secret.
#
# Usage: PFX_B64=... PFX_PASS=... [SIGN_IDENTITY="Mounsok Dara"] sign-macos.sh <path/to/App.app>
#
# A throw-away keychain is created for the job and the .p12 is deleted afterwards.
# Fails if the secret is missing, the identity is not found, or verification fails.
set -euo pipefail
APP="${1:?path to the .app bundle}"
: "${PFX_B64:?DESKTOP_SIGN_PFX_BASE64 secret is missing}" "${PFX_PASS:?DESKTOP_SIGN_PASSWORD secret is missing}"
IDENTITY="${SIGN_IDENTITY:-Mounsok Dara}"
TMP="${RUNNER_TEMP:-/tmp}"
[ -d "$APP" ] || { echo "app bundle not found: $APP"; exit 1; }

KC="$TMP/sign.keychain-db"; KP="$(openssl rand -hex 12)"
P12="$TMP/codesign.p12"
trap 'rm -f "$P12"' EXIT
echo "$PFX_B64" | base64 -d > "$P12"

security create-keychain -p "$KP" "$KC"
security set-keychain-settings -lut 3600 "$KC"
security unlock-keychain -p "$KP" "$KC"
security import "$P12" -k "$KC" -P "$PFX_PASS" -A -t cert -f pkcs12
security set-key-partition-list -S apple-tool:,apple: -s -k "$KP" "$KC" >/dev/null
security list-keychains -d user -s "$KC" $(security list-keychains -d user | tr -d '"')

HASH=$(security find-identity -p codesigning "$KC" | grep -m1 "$IDENTITY" | awk '{print $2}')
test -n "$HASH" || { echo "signing identity not found: $IDENTITY"; exit 1; }

codesign --force --deep --timestamp=none --sign "$HASH" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dv "$APP" 2>&1 | grep -E 'Authority|Signature|Identifier' || true
echo "OK: signed $APP"
