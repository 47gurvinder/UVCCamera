package org.uvccamera.flutter;

import android.content.Context;
import android.view.SurfaceView;
import android.view.View;

import io.agora.rtc2.video.VideoCanvas;
import io.flutter.plugin.platform.PlatformView;

// AgoraRemoteView.java
public class AgoraRemoteView implements PlatformView {
    private final SurfaceView surfaceView;

    public AgoraRemoteView(Context context, int viewId, Object args) {
        surfaceView = new SurfaceView(context);

    }

    public void setupAgora(int id) {
        // Set up remote video renderer
        AgoraManager.getInstance().getRtcEngine().setupRemoteVideo(new VideoCanvas(
                surfaceView,
                VideoCanvas.RENDER_MODE_HIDDEN,
                id
        ));
    }


    @Override
    public View getView() {
        return surfaceView;
    }

    @Override
    public void dispose() {
        // Cleanup if needed
    }
}


