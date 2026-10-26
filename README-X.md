# ecy_appX

HarmonyOS ArkUI-X 跨平台工程：ArkTS 界面（entry/），跨平台编译出安卓 apk（`.arkui-x/android`）与 iOS 工程（`.arkui-x/ios`）。

## 版本约束（当前配套）

| 组件 | 版本 | 说明 |
|---|---|---|
| DevEco Studio | 26.0.0 | 跨平台全链路编译入口，内置 hvigor 与 HarmonyOS SDK |
| hvigor 插件 @ohos/hvigor-ohos-arkui-x-plugin | 4.26.8 | 声明于 `hvigor/hvigor-config.json5` |
| HarmonyOS / ArkUI-X SDK | 26.0.0（API 26） | ArkUI-X SDK 位于 `~/Library/ArkUI-X/Sdk/26.0.0`；对应 `build-profile.json5` 的 targetSdk/compatibleSdkVersion 与 modelVersion |
| JDK（命令行 gradle 用） | 17 | AGP 9.1.1 要求 JDK 17+；本机用 `~/Library/Java/JavaVirtualMachines/ms-17.0.20.1` |
| AGP / Gradle | 9.1.1 / 9.4.0 | Gradle 版本由 wrapper 固定 |
| Android | compileSdk/targetSdk 33，minSdk 26 | 见 `.arkui-x/android/app/build.gradle`；ABI：arm64-v8a、armeabi-v7a |
| Xcode | 26.3 | 仅 iOS 打包需要，ArkUI-X 对其无强制最低版本 |

**四件套必须一一对齐**：项目 modelVersion = DevEco SDK API = ArkUI-X SDK 目录 = hvigor 插件次版本（插件版本号规律为 `4.<API>`）。任一错位即出现配置类构建故障。本机另装有 ArkUI-X SDK 24 一套（配套 DevEco 6.1.1 / 插件 4.24.4 / modelVersion 6.1.1），两套工具链互不通用。

AGP/Gradle 高于 ArkUI-X SDK 26.0.0 模板标准（模板为 AGP 7.4.1 / Gradle 8.4，本工程已升级）。再升 AGP 时注意 `compileSdkVersion` 旧写法在新版已废弃。

## 目标平台适配标准

| 平台 | 最低运行版本 |
|---|---|
| OpenHarmony | API 10+ |
| Android | Android 8（API level 26），与 minSdk 26 一致 |
| iOS | iOS 10（工程模板 deployment target 10.0） |

JDK 标准随工具链演进：官方旧文档建议 11.0.2，SDK 26 的 ace_tools 推荐 17+；实际下限由 AGP 决定（7.4.x 需 11+，9.x 需 17+）。统一用 JDK 17 可同时满足两套。

AndroidX：模板默认关闭（`gradle.properties` 中 `useAndroidX=false`）。安卓侧用到避让区（getWindowAvoidArea）等能力时需开启 useAndroidX 并引入 `androidx.core`，缺失时相关 API 静默返回空值。

## 跨平台 API 检查（11706007）

跨平台编译时，SDK 中未标记跨平台的 API 报 `11706007 can't support crossplatform application` 并阻断构建。`.arkui-x/arkui-x-config.json5` 中 `buildOption.ignoreCrossPlatform: true` 将其降为警告，不阻断。

- 开关按模块生效：`modules` 必须列出全部参与编译的模块（entry/common/home），缺列模块的报错仍为 ERROR
- 降级是临时手段，正式适配应改为平台分支调用或替换 API，之后移除开关

## 编译命令

脚本在 `scripts/`，自动探测 DevEco、ArkUI-X SDK 与可用 JDK（优先 17）：

| 目标 | 命令 | 产物 |
|---|---|---|
| 安卓 apk（ArkTS 编译 → 跨平台资产 → gradle 打包，全链路） | `scripts/build-apk.sh` | `.arkui-x/android/app/build/outputs/apk/debug/app-debug.apk` |
| 鸿蒙 HAP | `scripts/build-hap.sh` | `entry/build/default/outputs/default/*.hap`（未配签名则跳过签名） |
| 清理编译产物 | `scripts/clean.sh` | — |
| 安卓 apk 仅重打包（跨平台资产未变时） | `.arkui-x/android` 下：`JAVA_HOME=<JDK17路径> sh gradlew assembleDebug` | 同 apk |

- build-apk.sh 内部执行 hvigor `assembleApp`（DevEco Build App(s) 的命令行等价物），会顺带打 iOS 包，几秒、产物可无视；跨平台资产任务无独立命令行入口，无法跳过。若 Xcode 异常导致 iOS 打包失败，此时安卓资产已生成，脚本自动用 gradlew 收尾，不影响出 apk。
- promptAction 原生模块的 so 不在 assembleApp 自动生成的清单内（Toast 运行时 dlopen 加载），clean.sh 删 libs 后会缺失；build-apk.sh 构建前会自动补拷。
- 改了 ArkTS 后只跑 gradlew，apk 里仍是旧界面：gradlew 只打包已生成资产（`app/src/main/assets/arkui-x/`），须先跑 build-apk.sh 重新生成。assembleHap 也不更新跨平台资产。
- `gradlew` 模板无执行位，一律 `sh gradlew` 调用，不依赖执行位。

## 编译产物与版本控制

`.arkui-x` 下编译生成的文件一律不提交（`.gitignore` 已排除，重编译自动重建）：

| 路径 | 内容 |
|---|---|
| `.arkui-x/android/.gradle/` | Gradle 运行缓存 |
| `.arkui-x/android/app/build/` | gradle 构建输出（`**/build` 规则覆盖） |
| `.arkui-x/android/app/libs/` | 编译时从 ArkUI-X SDK 拷入的适配 so（libarkui_android.so 等） |
| `.arkui-x/android/app/src/main/assets/` | ArkTS 编译产物（modules.abc 等），apk 运行时资产 |
| `.arkui-x/ios/arkui-x/`、`.arkui-x/ios/frameworks/` | iOS 侧 ArkTS 产物、从 SDK 拷入的 xcframework |
| `.arkui-x/ios/app.xcodeproj/project.pbxproj` | 编译时 DevEco 自动注入 xcframework 引用而改写，已忽略以保持模板原版 |

需要提交的 `.arkui-x` 文件只有模板源：gradle 配置（build.gradle、settings.gradle、wrapper、gradle.properties、gradlew）、`app/src` 下 Java/res 源码、Xcode 工程骨架（`app.xcodeproj/`、`app/`）。

注意：pbxproj 被 gitignore 意味着新克隆机器上 Xcode 工程骨架不完整，需从 ArkUI-X SDK 模板（`~/Library/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/ace_tools/templates/ios`）拷回后再编译 iOS。

libs、assets、.gradle 不受 gradlew clean / DevEco Clean Project 影响（对 gradle 是输入、对 hvigor 是拷贝目标），彻底清理需手动删除。
