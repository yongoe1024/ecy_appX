package com.yongoe.ecyx;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import com.yongoe.ecyx.bridge.NativeBridge;
import com.yongoe.ecyx.bridge.SettingsBridge;

import ohos.stage.ability.adapter.StageActivity;


/**
 * Example ace activity class, which will load ArkUI-X ability instance.
 * StageActivity is provided by ArkUI-X
 * @see <a href=
 * "https://gitee.com/arkui-x/docs/blob/master/zh-cn/application-dev/tutorial/how-to-integrate-arkui-into-android.md">
 * to build android library</a>
 */
public class EntryEntryAbilityActivity extends StageActivity {
    private static final String LOG_TAG = "EcyApp";

    private final List<NativeBridge> bridges = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d(LOG_TAG, "EntryEntryAbilityActivity onCreate");

        setInstanceName("com.yongoe.ecyx:entry:EntryAbility:");
        // 桥接须在引擎加载（super.onCreate）前注册；新增桥接 = 新类 + 此处 add 一行
        bridges.add(new SettingsBridge(this));
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        // 先 super：StageActivity 需把结果转发给 ArkTS 侧 startAbilityForResult 的调用方
        super.onActivityResult(requestCode, resultCode, data);
        for (NativeBridge item : bridges) {
            item.dispatchActivityResult(requestCode);
        }
    }
}
