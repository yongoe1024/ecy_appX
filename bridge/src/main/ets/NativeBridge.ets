import bridge from '@arkui-x.bridge';

/**
 * 原生桥接框架：只负责桥接连接（createBridge）与原生消息路由，不含任何能力与业务语义。
 * 原生对端为安卓 bridge 包下的同名子类（iOS 同理）；桥接名、方法名、事件名是跨端协议，
 * 两端各自声明、保持一致。子类以单例收口创建（同名桥接重复创建行为未定义）。
 */
export abstract class NativeBridge {
  private readonly bridgeObject: bridge.BridgeObject;

  constructor(name: string) {
    this.bridgeObject = bridge.createBridge(name);
    this.bridgeObject.setMessageListener((data: bridge.Message): bridge.Response => {
      this.onNativeEvent(data);
      return data;
    });
  }

  /** 原生回发消息钩子，由子类消化（匹配事件、决议等待等） */
  protected abstract onNativeEvent(data: bridge.Message): void;

  /**
   * 调用原生方法（安卓侧同名 public 方法，反射路由）。
   * 返回值仅请求-响应类桥接有意义；命令+回执类（如开设置页）的返回值只表示
   * 命令已派发，真正的结果等 onNativeEvent 里的回发事件。
   */
  protected callNative(method: string): Promise<bridge.ResultValue> {
    return this.bridgeObject.callMethod(method);
  }
}
