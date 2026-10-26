package com.yongoe.ecy.bridge;

import android.app.Activity;

import ohos.ace.adapter.capability.bridge.BridgePlugin;

/**
 * 原生桥接框架：只负责 BridgePlugin 注册、持有宿主 Activity 与结果分发钩子，
 * 不含能力与业务语义。对应 ArkTS 侧 bridge 模块的 NativeBridge；桥接名、方法名、
 * 事件名是跨端协议，两端各自声明、保持一致。
 */
public abstract class NativeBridge extends BridgePlugin {
    protected final Activity activity;

    /**
     * @param activity 宿主 Activity，供子类拉起页面与切主线程
     * @param name 桥接名，与 ArkTS 侧对端一致（跨端协议）
     */
    protected NativeBridge(Activity activity, String name) {
        super(name, BridgeType.JSON_TYPE);
        this.activity = activity;
    }

    /** 宿主 Activity.onActivityResult 透传钩子，子类匹配自己的请求码；默认无结果要处理 */
    public void dispatchActivityResult(int requestCode) {
    }
}
