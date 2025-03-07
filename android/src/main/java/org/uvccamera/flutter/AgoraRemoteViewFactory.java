package org.uvccamera.flutter;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AgoraRemoteViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;
    private AgoraRemoteView agoraRemoteView;


    public AgoraRemoteViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;

    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        agoraRemoteView = new AgoraRemoteView(context, viewId, args);
        return agoraRemoteView;
    }

    public void setupAgora(int id) {
        agoraRemoteView.setupAgora(id);
    }
}
