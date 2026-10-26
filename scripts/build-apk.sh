#!/bin/bash
# 编译安卓 apk：assembleApp 全链路（ArkTS 编译 → 安卓/iOS 资产生成 → gradle 打包）。
# 链路会顺带打 iOS 包（几秒，产物可无视）；若 Xcode 异常导致 iOS 打包失败，
# 此时安卓资产已生成，用 gradlew 收尾兜底（资产任务无独立命令行入口，无法跳过 iOS）。
set -e
source "$(dirname "$0")/_env.sh"
cd "$ROOT"
# promptAction 原生模块不在 assembleApp 自动生成的 so 清单中（Toast 的 promptAction.showToast
# 运行时 dlopen 加载它），clean.sh 删 libs 后会缺失；assembleApp 只增不清 libs，故构建前补拷。
PROMPTACTION_SO="$(ls "$ARKUIX_SDK_HOME"/*/arkui-x/plugins/api/lib/promptaction/android-arm64-release/libpromptaction.so | head -1)"
mkdir -p .arkui-x/android/app/libs/arm64-v8a
cp -f "$PROMPTACTION_SO" .arkui-x/android/app/libs/arm64-v8a/
if ! "$HVIGORW" --mode project -p product=default -p buildMode=debug assembleApp; then
  # 模板中 gradlew 无执行位，用 sh 调用不依赖权限位
  ( cd "$ROOT/.arkui-x/android" && sh gradlew assembleDebug )
fi
echo "APK 输出: $ROOT/.arkui-x/android/app/build/outputs/apk/debug/app-debug.apk"
