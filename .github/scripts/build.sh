#!/usr/bin/env bash
# ================================================================
# 统一构建脚本
# 用法: bash .github/scripts/build.sh <platform>
# 环境变量: APP_VERSION, APP_BUILD_NUMBER, ANDROID_KEYSTORE_BASE64 等
# ================================================================
set -euo pipefail

PLATFORM="${1:?用法: build.sh <platform>}"

echo "=== Building $PLATFORM (v${APP_VERSION:-dev}+${APP_BUILD_NUMBER:-0}) ==="

# ── 平台特化步骤（flutter create 前后） ──
case "$PLATFORM" in
  windows)
    # 保存自定义文件
    mkdir -p /tmp/win_backup
    cp windows/runner/Runner.rc /tmp/win_backup/ 2>/dev/null || true
    cp -r windows/runner/resources/ /tmp/win_backup/resources/ 2>/dev/null || true
    cp windows/installer.iss /tmp/win_backup/ 2>/dev/null || true
    # 删除 windows/ 让 flutter create 完全重建（避免 "Wrote 0 files"）
    rm -rf windows/
    flutter create --project-name myriad_monitor --platforms windows .
    # 恢复自定义文件
    git checkout -- lib/
    cp /tmp/win_backup/Runner.rc windows/runner/Runner.rc 2>/dev/null || true
    cp -r /tmp/win_backup/resources/* windows/runner/resources/ 2>/dev/null || true
    cp /tmp/win_backup/installer.iss windows/ 2>/dev/null || true
    ;;
  macos)
    flutter create --project-name myriad_monitor --platforms macos .
    git checkout -- lib/ macos/Runner/Assets.xcassets/AppIcon.appiconset/
    ;;
  linux)
    sudo apt-get update && sudo apt-get install -y ninja-build libgtk-3-dev
    flutter create --project-name myriad_monitor --platforms linux .
    git checkout -- lib/ linux/packaging/icons/
    ;;
  android)
    flutter create --project-name myriad_monitor --platforms android .
    git checkout -- lib/
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
    git checkout -- lib/
    ;;
  *)
    echo "未知平台: $PLATFORM"; exit 1 ;;
esac

# ── 安装依赖 ──
flutter pub get

# ── pub get 后的二次修补 ──
case "$PLATFORM" in
  ios)
    # project.pbxproj 的 deployment target 在 flutter create 后已存在
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*/IPHONEOS_DEPLOYMENT_TARGET = 15.5/g' \
      ios/Runner.xcodeproj/project.pbxproj
    ;;
esac

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
    flutter build ios --release --no-codesign \
      --dart-define=APP_VERSION="${APP_VERSION:-dev}" \
      --dart-define=APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-0}"
    ;;
esac

echo "=== Build $PLATFORM complete ==="
