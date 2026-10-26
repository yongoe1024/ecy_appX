#!/bin/bash
# 编译安卓 apk：hvigor assembleApp 生成跨平台资产（ArkTS 编译 → 安卓/iOS 资产 → 各端打包），
# 移除 entryTest 资产后用 gradle 重新打包安卓（iOS 重跑 xcodebuild）。
# 资产任务无独立命令行入口，无法在 assembleApp 内部插入移除步骤，故出包后二次打包（约10秒）。
set -e
source "$(dirname "$0")/_env.sh"
cd "$ROOT"
# promptAction 原生模块不在 assembleApp 自动生成的 so 清单中（Toast 的 promptAction.showToast
# 运行时 dlopen 加载它），新克隆/clean.sh 深度清理后 libs 为空即缺失；assembleApp 只增不清 libs，补拷幂等。
PROMPTACTION_SO="$ARKUIX_SDK_HOME/$ARKUIX_API_DIR/arkui-x/plugins/api/lib/promptaction/android-arm64-release/libpromptaction.so"
mkdir -p .arkui-x/android/app/libs/arm64-v8a
cp -f "$PROMPTACTION_SO" .arkui-x/android/app/libs/arm64-v8a/
# librouter.xcframework 同不在 assembleApp 自动拷贝清单中：iOS 编译注入引用但 frameworks 缺失，
# xcodebuild 报 no XCFramework found；新克隆/clean.sh 深度清理后缺失，补拷幂等
mkdir -p .arkui-x/ios/frameworks
cp -R "$ARKUIX_SDK_HOME/$ARKUIX_API_DIR/arkui-x/plugins/api/xcframework/ios-release/librouter.xcframework" \
  .arkui-x/ios/frameworks/
if ! "$HVIGORW" --mode project -p product=default -p buildMode=debug assembleApp; then
  echo "hvigor assembleApp 失败，若系 Xcode 异常则资产已生成，继续 gradle 收尾"
fi
# hvigor 4.26.8 debug 构建会把 ohosTest(entryTest) 模块打进跨平台资产，其 module.json 的
# routerMap 引用悬空（运行时解压不出 router_map.json），安卓/iOS 引擎解析失败会清空整张
# 路由表（logcat: can't find name in config file → 页面空白）。移除后重新打包（约10秒）。
rm -rf .arkui-x/android/app/src/main/assets/arkui-x/entryTest .arkui-x/ios/arkui-x/entryTest
# 模板中 gradlew 无执行位，用 sh 调用不依赖权限位
( cd "$ROOT/.arkui-x/android" && sh gradlew assembleDebug ) || exit 1
# iOS 包在 assembleApp 内已按含 entryTest 的资产打过，重跑 xcodebuild 拿干净包；失败不影响安卓产物
( cd "$ROOT/.arkui-x/ios" && xcodebuild -project app.xcodeproj -sdk iphoneos -configuration Debug clean build \
    CONFIGURATION_BUILD_DIR="$ROOT/.arkui-x/ios/build/outputs/app" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= >/dev/null 2>&1 ) \
  || echo "iOS 重打包跳过（Xcode 异常，不影响安卓）"
echo "APK 输出: $ROOT/.arkui-x/android/app/build/outputs/apk/debug/app-debug.apk"
