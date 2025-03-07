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

import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.video.VideoCanvas;
import io.flutter.plugin.platform.PlatformView;

public class AgoraRemoteView implements PlatformView {
    private final TextureView textureView;
    private final FrameLayout frameLayout;

    public AgoraRemoteView(Context context, int viewId, Object args) {
        frameLayout = new FrameLayout(context);
        textureView = new TextureView(context);
        textureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(android.graphics.SurfaceTexture surface, int width, int height) {
                Log.e("MyAppAgora", "TextureView Available: " + width + "x" + height);
            }

            @Override
            public void onSurfaceTextureSizeChanged(android.graphics.SurfaceTexture surface, int width, int height) {
            }

            @Override
            public boolean onSurfaceTextureDestroyed(android.graphics.SurfaceTexture surface) {
                return false;
            }

            @Override
            public void onSurfaceTextureUpdated(android.graphics.SurfaceTexture surface) {
            }
        });

        frameLayout.addView(textureView);
    }

    public void setupAgora(int id) {
        // Set up remote video renderer
        Log.e("MyAppAgora", "setupAgora uid: " + id);
        new Handler(Looper.getMainLooper()).post(() -> {
            RtcEngine rtcEngine = AgoraManager.getInstance().getRtcEngine();

            if (rtcEngine == null) {
                Log.e("MyAppAgora", "RtcEngine is NULL! Check initialization.");
                return;
            }

            rtcEngine.muteRemoteVideoStream(id, false); // Unmute the video stream
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


