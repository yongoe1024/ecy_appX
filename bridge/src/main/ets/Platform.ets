import { deviceInfo } from '@kit.BasicServicesKit';

/**
 * 运行平台判断。
 *
 * deviceInfo.osFullName 跨平台可用（ArkUI-X 文档「运行态差异化」）：
 * 鸿蒙返回 OpenHarmony/HarmonyOS 开头，安卓返回 Android x，苹果设备返回 iOS/iPadOS x。
 *
 * bridge 模块只存放官方跨平台清单之外、需要平台分支或原生桥接的部分；
 * 其余 API 由 ArkUI-X 引擎适配（对照 SDK apiConfig.json 官方跨平台模块清单）。
 */
export class Platform {
  static isHarmony(): boolean {
    const name = deviceInfo.osFullName
    return name.startsWith('OpenHarmony') || name.startsWith('HarmonyOS')
  }

  static isAndroid(): boolean {
    return deviceInfo.osFullName.startsWith('Android')
  }
}
