package org.uvccamera.flutter;

import android.content.Context;

import io.agora.rtc2.Constants;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;

public class AgoraManager {

    private static AgoraManager instance;
    private RtcEngine rtcEngine;
    private String appId; // Your Agora App ID

    private AgoraManager(Context applicationContext, String appId, IRtcEngineEventHandler eventHandler) {
        this.appId = appId;
        try {
            rtcEngine = RtcEngine.create(applicationContext, appId, eventHandler);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static synchronized AgoraManager getInstance(Context applicationContext, String appId, IRtcEngineEventHandler eventHandler) {
        if (instance == null) {
            instance = new AgoraManager(applicationContext, appId, eventHandler);
        }
        return instance;
    }

    public static synchronized AgoraManager getInstance() {
        if (instance == null) {
            throw new IllegalStateException("AgoraManager must be initialized with getInstance(appId, eventHandler) first.");
        }
        return instance;
    }

    public RtcEngine getRtcEngine() {
        return rtcEngine;
    }

    public void destroy() {
        if (rtcEngine != null) {
            rtcEngine.leaveChannel();
            RtcEngine.destroy();
            rtcEngine = null;
            instance = null;
        }
    }
}
