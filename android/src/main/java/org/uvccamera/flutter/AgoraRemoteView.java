package org.uvccamera.flutter;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.util.Map;

import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.video.VideoCanvas;
import io.flutter.plugin.platform.PlatformView;

public class AgoraRemoteView implements PlatformView {
    private final TextureView textureView;
    private final FrameLayout frameLayout;

    public AgoraRemoteView(Context context, int viewId, Object args) {
        frameLayout = new FrameLayout(context);
        textureView = new TextureView(context);
        frameLayout.addView(textureView);
        if (args instanceof Map) {
            Map<String, Object> creationParams = (Map<String, Object>) args;
            if (creationParams.containsKey("uid")) {
                int uid = (int) creationParams.get("uid");
                setupAgora(uid);
            }
        }
    }

    public void setupAgora(int id) {

        Log.e("MyAppAgora", "Setting up Agora Remote View for uid: " + id);

        new Handler(Looper.getMainLooper()).post(() -> {
            RtcEngine rtcEngine = AgoraManager.getInstance().getRtcEngine();

            if (rtcEngine == null) {
                Log.e("MyAppAgora", "RtcEngine is NULL! Check initialization.");
                return;
            }

            rtcEngine.muteRemoteVideoStream(id, false);
            rtcEngine.setupRemoteVideo(new VideoCanvas(
                    textureView,
                    VideoCanvas.RENDER_MODE_HIDDEN,
                    id
            ));

            Log.e("MyAppAgora", "Remote video setup completed for uid: " + id);
        });
    }


    @Override
    public View getView() {
        return frameLayout;
    }

    @Override
    public void dispose() {
        // Cleanup if needed
    }
}


