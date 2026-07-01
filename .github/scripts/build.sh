#!/usr/bin/env bash
# ================================================================
# 统一构建脚本
# 用法: bash .github/scripts/build.sh <platform>
# 环境变量: APP_VERSION, APP_BUILD_NUMBER, ANDROID_KEYSTORE_BASE64 等
# ================================================================
set -euo pipefail

PLATFORM="${1:?用法: build.sh <platform>}"

echo "=== Building $PLATFORM (v${APP_VERSION:-dev}+${APP_BUILD_NUMBER:-0}) ==="

# ── 平台特化步骤 ──
case "$PLATFORM" in
  windows)
    flutter create --project-name myriad_monitor --platforms windows .
    git checkout -- windows/runner/Runner.rc windows/runner/resources/ || true
    ;;
  macos)
    flutter create --project-name myriad_monitor --platforms macos .
    git checkout -- macos/Runner/Assets.xcassets/AppIcon.appiconset/ || true
    ;;
  linux)
    sudo apt-get update && sudo apt-get install -y ninja-build libgtk-3-dev
    flutter create --project-name myriad_monitor --platforms linux .
    git checkout -- linux/packaging/icons/ || true
    ;;
  android)
    flutter create --project-name myriad_monitor --platforms android .
    if [ -n "${ANDROID_KEYSTORE_BASE64:-}" ]; then
      echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks
      cat <<EOF > android/key.properties
storePassword=${KEY_STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=upload-keystore.jks
EOF
      sed -i '/^android\.newDsl=/d' android/gradle.properties
    fi
    ;;
  ios)
    flutter create --project-name myriad_monitor --platforms ios .
    echo 'platform :ios, "15.5"' | cat - ios/Podfile > ios/Podfile.tmp && mv ios/Podfile.tmp ios/Podfile
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*/IPHONEOS_DEPLOYMENT_TARGET = 15.5/g' ios/Runner.xcodeproj/project.pbxproj
    ;;
  *)
    echo "未知平台: $PLATFORM"; exit 1 ;;
esac

# ── 通用步骤 ──
flutter pub get

# ── 构建 ──
DART_DEFINES="--dart-define=APP_VERSION=${APP_VERSION:-dev} --dart-define=APP_BUILD_NUMBER=${APP_BUILD_NUMBER:-0}"

case "$PLATFORM" in
  windows)
    eval flutter build windows --release "$DART_DEFINES"
    ;;
  macos)
    eval flutter build macos --release "$DART_DEFINES"
    ;;
  linux)
    eval flutter build linux --release "$DART_DEFINES"
    ;;
  android)
    eval flutter build apk --release "$DART_DEFINES" --build-number="${APP_BUILD_NUMBER:-0}"
    eval flutter build apk --debug "$DART_DEFINES" --build-number="${APP_BUILD_NUMBER:-0}"
    ;;
  ios)
    eval flutter build ios --release --no-codesign "$DART_DEFINES" -- CODE_SIGNING_ALLOWED=NO
    ;;
esac

echo "=== Build $PLATFORM complete ==="
