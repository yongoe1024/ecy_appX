#!/bin/bash
# 编译鸿蒙 HAP（只出 HAP，不生成安卓/iOS 跨平台资产）
set -e
source "$(dirname "$0")/_env.sh"
cd "$ROOT"
"$HVIGORW" --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap
echo "HAP 输出: $ROOT/entry/build/default/outputs/default/"
