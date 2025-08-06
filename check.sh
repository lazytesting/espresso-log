#!/bin/bash

# Usage:
# ./validate_ios_build_inputs.sh /path/to/exportOptions.plist /path/to/flutter_project/ios [--mode pre|post]

set -e

EXPORT_PLIST="$1"
IOS_PROJECT_PATH="$2"
MODE="${3:-all}"
PBXPROJ_PATH="$IOS_PROJECT_PATH/Runner.xcodeproj/project.pbxproj"
ARCHIVE_APP_PATH="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"

if [ ! -f "$EXPORT_PLIST" ]; then
    echo "❌ exportOptions.plist not found: $EXPORT_PLIST"
    exit 1
fi

if [ ! -f "$PBXPROJ_PATH" ]; then
    echo "❌ project.pbxproj not found at: $PBXPROJ_PATH"
    exit 1
fi

if [ ! -d "$IOS_PROJECT_PATH" ]; then
    echo "❌ iOS project directory not found: $IOS_PROJECT_PATH"
    exit 1
fi

echo "📋 Reading exportOptions.plist..."

TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :teamID" "$EXPORT_PLIST" 2>/dev/null || echo "")
EXPORT_CERT=$(/usr/libexec/PlistBuddy -c "Print :signingCertificate" "$EXPORT_PLIST" 2>/dev/null || echo "")
EXPORT_METHOD=$(/usr/libexec/PlistBuddy -c "Print :method" "$EXPORT_PLIST" 2>/dev/null || echo "")

PROJECT_BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = .*;' "$PBXPROJ_PATH" | head -n1 | awk -F'= ' '{print $2}' | tr -d '";')
if [ -z "$PROJECT_BUNDLE_ID" ]; then
    echo "❌ Could not extract PRODUCT_BUNDLE_IDENTIFIER from project.pbxproj"
    exit 1
fi

PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print :provisioningProfiles:$PROJECT_BUNDLE_ID" "$EXPORT_PLIST" 2>/dev/null || echo "")

# Resolve actual path to installed provisioning profile
PROFILE_PATH=$(find ~/Library/MobileDevice/Provisioning\ Profiles -name '*.mobileprovision' -exec sh -c '
  for profile; do
    NAME=$(security cms -D -i "$profile" 2>/dev/null | /usr/libexec/PlistBuddy -c "Print :Name" /dev/stdin 2>/dev/null || true)
    if [ "$NAME" = "'$PROFILE_NAME'" ]; then
      echo "$profile"
      break
    fi
  done
' _ {} +)

if [ -z "$PROFILE_NAME" ] || [ -z "$PROFILE_PATH" ]; then
    echo "❌ Could not resolve provisioning profile path for name: $PROFILE_NAME"
    exit 1
fi
    echo "❌ No provisioning profile name found in exportOptions.plist for bundle ID: $PROJECT_BUNDLE_ID"
    exit 1
fi

if [[ "$MODE" == "post" ]]; then
  echo "📦 Post-archive validation..."

  if [ -f "$ARCHIVE_APP_PATH/embedded.mobileprovision" ]; then
      echo "✔️ embedded.mobileprovision found in archived Runner.app"

      EMBEDDED_PROFILE_NAME=$(security cms -D -i "$ARCHIVE_APP_PATH/embedded.mobileprovision" > "$PLIST_TMP.embedded" && /usr/libexec/PlistBuddy -c "Print :Name" "$PLIST_TMP.embedded" || echo "")
      if [ -n "$EMBEDDED_PROFILE_NAME" ]; then
          echo "✔️ Embedded profile name: $EMBEDDED_PROFILE_NAME"
          if [ "$EMBEDDED_PROFILE_NAME" != "$PROFILE_NAME" ]; then
              echo "❌ Embedded profile name does not match exportOptions.plist"
              echo "    → embedded: $EMBEDDED_PROFILE_NAME"
              echo "    → expected: $PROFILE_NAME"
              exit 1
          else
              echo "✔️ Embedded profile name matches exportOptions.plist"
          fi
      else
          echo "❌ Could not parse embedded profile"
          exit 1
      fi
  else
      echo "❌ embedded.mobileprovision is missing in archived Runner.app"
      echo "💡 This usually means the provisioning profile was not embedded during 'xcodebuild archive'"
      exit 1
  fi

  echo "✅ Post-archive checks passed."
  exit 0
fi

# From here down: pre-archive validation...

PLIST_TMP=$(mktemp -t profile.plist)
/usr/libexec/PlistBuddy -x -c "Print" /dev/stdin <<< $(security cms -D -i "$PROFILE_PATH") > "$PLIST_TMP"

PROFILE_TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" "$PLIST_TMP")
FULL_APP_ID=$(/usr/libexec/PlistBuddy -c "Print Entitlements:application-identifier" "$PLIST_TMP")
PROFILE_BUNDLE_ID="${FULL_APP_ID#"$PROFILE_TEAM_ID."}"

if [ "$PROFILE_BUNDLE_ID" != "$PROJECT_BUNDLE_ID" ]; then
    echo "❌ Bundle ID mismatch:"
    echo "    → project.pbxproj: $PROJECT_BUNDLE_ID"
    echo "    → provisioning profile: $PROFILE_BUNDLE_ID"
    exit 1
else
    echo "✔️ Bundle ID matches: $PROJECT_BUNDLE_ID"
fi

if [ "$TEAM_ID" != "$PROFILE_TEAM_ID" ]; then
    echo "❌ teamID mismatch:"
    echo "    → exportOptions.plist: $TEAM_ID"
    echo "    → provisioning profile: $PROFILE_TEAM_ID"
    exit 1
else
    echo "✔️ teamID matches: $TEAM_ID"
fi

if [[ "$EXPORT_METHOD" =~ ^(app-store|ad-hoc|enterprise|development)$ ]]; then
    echo "✔️ method is valid: $EXPORT_METHOD"
else
    echo "❌ Invalid or missing 'method': $EXPORT_METHOD"
    exit 1
fi

if [ -n "$EXPORT_CERT" ]; then
    echo "✔️ signingCertificate present: $EXPORT_CERT"
    CERT_MATCH=$(security find-identity -v -p codesigning | grep "$EXPORT_CERT" || true)
    if [ -z "$CERT_MATCH" ]; then
        echo "❌ Signing certificate '$EXPORT_CERT' not found in keychain"
        echo "💡 Run 'security find-identity -v -p codesigning' to see available certificates"
        exit 1
    else
        echo "✔️ Signing certificate '$EXPORT_CERT' found in keychain"
    fi
else
    echo "ℹ️ No signingCertificate specified (optional)"
fi

EXPIRATION_DATE=$(/usr/libexec/PlistBuddy -c "Print :ExpirationDate" "$PLIST_TMP" 2>/dev/null)
if [ -n "$EXPIRATION_DATE" ]; then
    EXPIRY_EPOCH=$(date -j -f "%a %b %d %T %Z %Y" "$EXPIRATION_DATE" "+%s")
    NOW_EPOCH=$(date "+%s")
    if [ "$NOW_EPOCH" -ge "$EXPIRY_EPOCH" ]; then
        echo "❌ Provisioning profile is expired: $EXPIRATION_DATE"
        exit 1
    else
        echo "✔️ Provisioning profile is valid (expires: $EXPIRATION_DATE)"
    fi
else
    echo "⚠️ Unable to determine profile expiration date"
fi

if ! security find-certificate -c "$EXPORT_CERT" -p > /dev/null 2>&1; then
    echo "❌ Code signing certificate '$EXPORT_CERT' exists but is not trusted"
    exit 1
else
    echo "✔️ Code signing certificate '$EXPORT_CERT' is trusted"
fi

ENTITLEMENTS=$(security cms -D -i "$PROFILE_PATH" | plutil -extract Entitlements xml1 -o - - | grep 'get-task-allow' || true)
if [[ "$EXPORT_METHOD" == "app-store" && "$ENTITLEMENTS" =~ true ]]; then
    echo "❌ 'get-task-allow' is true but method is 'app-store' — this indicates a development profile"
    exit 1
else
    echo "✔️ Entitlements match export method: $EXPORT_METHOD"
fi

PROVISIONED_DEVICES=$(/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$PLIST_TMP" 2>/dev/null || echo "")
if [ -n "$PROVISIONED_DEVICES" ]; then
    echo "ℹ️ Provisioned devices are listed in profile (development or ad-hoc profile)"
    echo "$PROVISIONED_DEVICES"
    if ! echo "$PROVISIONED_DEVICES" | grep -q "Mac-"; then
        echo "❌ CI Mac is likely not listed in ProvisionedDevices — signing will fail"
        echo "💡 Use an App Store or Ad Hoc profile that does not require specific device registration"
        exit 1
    else
        echo "✔️ CI device appears to be included in ProvisionedDevices"
    fi
else
    echo "✔️ No specific devices listed — likely an App Store or enterprise profile"
fi

echo "✅ Pre-archive checks passed."
exit 0
