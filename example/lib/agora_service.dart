import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  late RtcEngine engine;
  bool isInitialized = false;

  Future<void> initializeAgora({
    required String appId,
    required String token,
    required String channelName,
    required int uid,
  }) async {
    engine = createAgoraRtcEngine();
    await engine?.initialize(RtcEngineContext(appId: appId));


    await engine
        .getMediaEngine()
        .setExternalVideoSource(enabled: true, useTexture: false);
    await engine?.enableVideo();
    await engine.startPreview(sourceType: VideoSourceType.videoSourceCustom);


    await engine?.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    isInitialized = true;
  }
}
