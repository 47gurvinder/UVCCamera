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
    await engine.initialize(RtcEngineContext(appId: appId));

    await engine.enableVideo();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(),
    );

    isInitialized = true;
  }
}
