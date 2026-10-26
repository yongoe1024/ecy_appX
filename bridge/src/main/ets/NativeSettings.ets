import bridge from '@arkui-x.bridge';
import { NativeBridge } from './NativeBridge';

// 与 SettingsBridge.java 的 LOCATION_CLOSED_EVENT 一致（跨端协议，两端各自声明）
const LOCATION_CLOSED_EVENT: string = 'locationSettingsClosed';
// 与 SettingsBridge.java 的 APP_DETAILS_CLOSED_EVENT 一致
const APP_DETAILS_CLOSED_EVENT: string = 'appDetailsSettingsClosed';

/** 在途等待：关闭事件名与决议器的配对 */
interface PendingWait {
  event: string
  resolve: () => void
}

/**
 * 安卓系统设置页桥接（原生对端：SettingsBridge.java）。
 * 鸿蒙/iOS 无对端，调用会 reject，调用方需保证仅在安卓分支使用。
 */
export class NativeSettings extends NativeBridge {
  private static instance: NativeSettings | undefined;
  // 同一时刻至多一个在途页面：waitPage 内结构保证（已有等待时拒绝新调用），
  // 不依赖调用方互斥约定
  private pending: PendingWait | undefined;

  // 同名桥接重复创建的引擎行为未定义，单例收口创建
  static getInstance(): NativeSettings {
    if (!NativeSettings.instance) {
      NativeSettings.instance = new NativeSettings();
    }
    return NativeSettings.instance;
  }

  private constructor() {
    super('NativeSettingsBridge');
  }

  /**
   * 原生回发消息进来：命中在途等待的关闭事件则清槽并决议 Promise；
   * 未在等待或对不上号则忽略
   */
  protected onNativeEvent(data: bridge.Message): void {
    const pending = this.pending;
    if (pending && data === pending.event) {
      this.pending = undefined;
      pending.resolve();
    }
  }

  /**
   * 打开系统定位服务设置页，Promise 在用户从设置页返回（原生回发关闭事件）时决议，
   * 之后由调用方复查 geoLocationManager.isLocationEnabled()。
   * @throws 已有设置页跳转在途、原生对端不存在或方法调用失败时 reject
   */
  openLocationSettingsPage(): Promise<void> {
    return this.waitPage(LOCATION_CLOSED_EVENT, 'openLocationSettings')
  }

  /**
   * 打开应用详情设置页（权限管理入口），Promise 在用户从设置页返回（原生回发关闭事件）时决议，
   * 之后由调用方在下次权限检查中感知变更。
   * @throws 已有设置页跳转在途、原生对端不存在或方法调用失败时 reject
   */
  openAppDetailsSettingsPage(): Promise<void> {
    return this.waitPage(APP_DETAILS_CLOSED_EVENT, 'openAppDetailsSettings')
  }

  /**
   * 设置页跳转通用执行体：先挂起再派发、失败回收，绑定在此方法内。
   * 已有在途等待时拒绝新调用并保留旧等待——被覆盖的等待 Promise 永不决议，等同挂死。
   */
  private waitPage(event: string, method: string): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      if (this.pending) {
        reject(new Error('已有设置页跳转在途，同一时刻仅允许一个等待'));
        return;
      }
      this.pending = { event: event, resolve: resolve };
      this.callNative(method).catch((err: Error) => {
        this.pending = undefined;
        reject(err);
      });
    });
  }
}
