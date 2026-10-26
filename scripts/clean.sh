#!/bin/bash
# 删除全部编译产物（均为 .gitignore 排除项），由 build-hap.sh / build-apk.sh 重新生成。
# 注意 libs、assets、.gradle 不受 gradlew clean / DevEco Clean Project 影响，需如此手动删除。
cd "$(dirname "$0")/.." || exit 1
rm -rf build entry/build \
  .arkui-x/android/.gradle .arkui-x/android/app/build .arkui-x/android/app/.cxx \
  .arkui-x/android/app/libs .arkui-x/android/app/src/main/assets \
  .arkui-x/ios/build .arkui-x/ios/arkui-x .arkui-x/ios/frameworks
echo "已清理。重新构建：scripts/build-hap.sh 或 scripts/build-apk.sh"
