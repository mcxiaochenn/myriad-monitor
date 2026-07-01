#!/usr/bin/env bash
# ================================================================
# 统一打包脚本（bash 兼容）
# 用法: bash .github/scripts/package.sh <platform>
# 环境变量: APP_VERSION, APP_BUILD_NUMBER
# 注意: Windows installer 需要 PowerShell，保留在 YAML 中
# ================================================================
set -euo pipefail

PLATFORM="${1:?用法: package.sh <platform>}"
VER="${APP_VERSION:-dev}"
CODE="${APP_BUILD_NUMBER:-0}"
SUFFIX=$([[ "$CODE" != "0" ]] && echo "v${VER}_${CODE}" || echo "dev")

echo "=== Packaging $PLATFORM → myriad-monitor-${SUFFIX} ==="

case "$PLATFORM" in
  windows)
    cd windows-build && zip -r "../myriad-monitor-${SUFFIX}-windows-portable.zip" . && cd ..
    ;;
  macos)
    cd macos-build && zip -r "../myriad-monitor-${SUFFIX}-macos.zip" . && cd ..
    ;;
  linux)
    cd linux-build && tar -czf "../myriad-monitor-${SUFFIX}-linux.tar.gz" . && cd ..
    ;;
  android)
    mv android-build/app-release.apk "myriad-monitor-${SUFFIX}-android-release.apk"
    mv android-build/app-debug.apk "myriad-monitor-${SUFFIX}-android-debug.apk"
    ;;
  *)
    echo "未知平台: $PLATFORM"; exit 1 ;;
esac

echo "=== Package $PLATFORM complete ==="
