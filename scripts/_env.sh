#!/bin/bash
# 公共环境探测：被本目录其他脚本 source，勿直接执行。
# Gradle 8.4 不支持 Java 21+（本机系统默认 26 不可用），需 JDK 11~20，优先取 17。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVECO="/Applications/DevEco-Studio.app"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO/Contents/sdk}"
export ARKUIX_SDK_HOME="${ARKUIX_SDK_HOME:-$HOME/Library/ArkUI-X/Sdk}"
# SDK 子目录须与 build-profile 的 targetSdkVersion 同 API（本机 24 与 26.0.0 并存）；
# 安卓侧 CMakeLists 的引擎头文件路径同为硬编码，改 API 线时两处一起改
export ARKUIX_API_DIR="${ARKUIX_API_DIR:-26.0.0}"
export NODE_HOME="${NODE_HOME:-$DEVECO/Contents/tools/node}"
export OHPM_HOME="${OHPM_HOME:-$DEVECO/Contents/tools/ohpm}"
export PATH="$NODE_HOME/bin:$PATH"
HVIGORW="${HVIGORW:-$DEVECO/Contents/tools/hvigor/bin/hvigorw}"

java_ok() { [ -n "$1" ] && "$1/bin/java" -version 2>&1 | grep -qE 'version "(1[1-9]|20)\.'; }
if ! java_ok "$JAVA_HOME"; then
  for d in "$HOME"/Library/Java/JavaVirtualMachines/*17*/Contents/Home "$DEVECO/Contents/jbr"; do
    if java_ok "$d"; then export JAVA_HOME="$d"; break; fi
  done
fi
java_ok "$JAVA_HOME" || { echo "未找到可用 JDK（需 11~20）"; exit 1; }
