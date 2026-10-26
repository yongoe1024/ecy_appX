package com.yongoe.ecyx.bridge;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;

/**
 * ArkTS 侧 NativeSettings 的原生对端：系统设置页跳转。
 * 桥接名/方法名/关闭事件名与 NativeSettings.ets 一致（跨端协议，两端各自声明）。
 */
public class SettingsBridge extends NativeBridge {
    // 与 NativeSettings.ets 的 LOCATION_CLOSED_EVENT 常量一致，
    // ArkTS 侧等待返回的 Promise 靠此消息决议
    private static final String LOCATION_CLOSED_EVENT = "locationSettingsClosed";
    // 与 NativeSettings.ets 的 APP_DETAILS_CLOSED_EVENT 常量一致
    private static final String APP_DETAILS_CLOSED_EVENT = "appDetailsSettingsClosed";
    // StageActivity 的请求码由 ArkTS startAbilityForResult 调用方传入、权限插件走
    // onRequestPermissionsResult 通道，均不占用 onActivityResult 通道；新增桥接勿复用
    private static final int REQUEST_LOCATION_SETTINGS = 1001;
    private static final int REQUEST_APP_DETAILS = 1002;

    public SettingsBridge(Activity activity) {
        super(activity, "NativeSettingsBridge");
    }

    // ArkTS 侧 callMethod 的对端；bridge 方法在子线程执行，拉起页面须切回主线程。
    // 返回值仅表示页面已派发，用户返回走 LOCATION_CLOSED_EVENT 事件
    public boolean openLocationSettings() {
        activity.runOnUiThread(() -> activity.startActivityForResult(
                new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS), REQUEST_LOCATION_SETTINGS));
        return true;
    }

    // 应用详情页（权限入口在其中的「权限」子页），返回回执与 openLocationSettings 同构，
    // ArkTS 侧等待返回后由下次权限检查感知变更
    public boolean openAppDetailsSettings() {
        Uri packageUri = Uri.parse("package:" + activity.getPackageName());
        activity.runOnUiThread(() -> activity.startActivityForResult(
                new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri), REQUEST_APP_DETAILS));
        return true;
    }

    /** 命中本桥请求码（用户从设置页返回）则回发对应关闭事件，决议 ArkTS 侧等待 */
    @Override
    public void dispatchActivityResult(int requestCode) {
        if (requestCode == REQUEST_LOCATION_SETTINGS) {
            sendMessage(LOCATION_CLOSED_EVENT);
        } else if (requestCode == REQUEST_APP_DETAILS) {
            sendMessage(APP_DETAILS_CLOSED_EVENT);
        }
    }
}
