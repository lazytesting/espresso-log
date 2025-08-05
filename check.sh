#!/bin/bash

# Usage:
# ./validate_ios_build_inputs.sh /path/to/exportOptions.plist /path/to/flutter_project/ios

set -e

EXPORT_PLIST="$1"
IOS_PROJECT_PATH="$2"
PBXPROJ_PATH="$IOS_PROJECT_PATH/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$EXPORT_PLIST" ]; then
    echo "❌ exportOptions.plist not found: $EXPORT_PLIST"
    exit 1
fi

if [ ! -f "$PBXPROJ_PATH" ]; then
    echo "❌ project.pbxproj not found at: $PBXPROJ_PATH"
    exit 1
fi

echo "📋 Reading exportOptions.plist..."

# Extract required values from exportOptions.plist
TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :teamID" "$EXPORT_PLIST" 2>/dev/null || echo "")
EXPORT_CERT=$(/usr/libexec/PlistBuddy -c "Print :signingCertificate" "$EXPORT_PLIST" 2>/dev/null || echo "")
EXPORT_METHOD=$(/usr/libexec/PlistBuddy -c "Print :method" "$EXPORT_PLIST" 2>/dev/null || echo "")

# Extract bundle ID from Xcode project
PROJECT_BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = .*;' "$PBXPROJ_PATH" | head -n1 | awk -F'= ' '{print $2}' | tr -d '";')
if [ -z "$PROJECT_BUNDLE_ID" ]; then
    echo "❌ Could not extract PRODUCT_BUNDLE_IDENTIFIER from project.pbxproj"
    exit 1
fi

PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print :provisioningProfiles:$PROJECT_BUNDLE_ID" "$EXPORT_PLIST" 2>/dev/null || echo "")
if [ -z "$PROFILE_NAME" ]; then
    echo "❌ No provisioning profile name found in exportOptions.plist for bundle ID: $PROJECT_BUNDLE_ID"
    exit 1
fi

# Search installed profiles
echo "🔍 Searching installed profiles for name: $PROFILE_NAME"
PROFILE_PATH=$(grep -l "$PROFILE_NAME" ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | head -n1)

if [ -z "$PROFILE_PATH" ]; then
    echo "❌ Could not find provisioning profile named '$PROFILE_NAME' in ~/Library/MobileDevice/Provisioning Profiles"
    exit 1
fi

echo "✔️ Found installed provisioning profile: $PROFILE_PATH"

# Parse provisioning profile
PLIST_TMP=$(mktemp -t profile.plist)
/usr/libexec/PlistBuddy -x -c "Print" /dev/stdin <<< $(security cms -D -i "$PROFILE_PATH") > "$PLIST_TMP"

PROFILE_TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" "$PLIST_TMP")
FULL_APP_ID=$(/usr/libexec/PlistBuddy -c "Print Entitlements:application-identifier" "$PLIST_TMP")
PROFILE_BUNDLE_ID="${FULL_APP_ID#"$PROFILE_TEAM_ID."}"

# Compare Bundle ID
if [ "$PROFILE_BUNDLE_ID" != "$PROJECT_BUNDLE_ID" ]; then
    echo "❌ Bundle ID mismatch:"
    echo "    → project.pbxproj: $PROJECT_BUNDLE_ID"
    echo "    → provisioning profile: $PROFILE_BUNDLE_ID"
    exit 1
else
    echo "✔️ Bundle ID matches: $PROJECT_BUNDLE_ID"
fi

# Compare team ID
if [ "$TEAM_ID" != "$PROFILE_TEAM_ID" ]; then
    echo "❌ teamID mismatch:"
    echo "    → exportOptions.plist: $TEAM_ID"
    echo "    → provisioning profile: $PROFILE_TEAM_ID"
    exit 1
else
    echo "✔️ teamID matches: $TEAM_ID"
fi

# Validate method
if [[ "$EXPORT_METHOD" =~ ^(app-store|ad-hoc|enterprise|development)$ ]]; then
    echo "✔️ method is valid: $EXPORT_METHOD"
else
    echo "❌ Invalid or missing 'method': $EXPORT_METHOD"
    exit 1
fi

# Validate signingCertificate presence
if [ -n "$EXPORT_CERT" ]; then
    echo "✔️ signingCertificate present: $EXPORT_CERT"

    # Check certificate exists in keychain
    echo "🔍 Checking if signing certificate '$EXPORT_CERT' is in keychain..."
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

echo "✅ All validations passed."
