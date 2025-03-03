import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:uvccamera/uvccamera.dart';
import 'package:uvccamera_example/agora_service.dart';
import 'package:uvccamera_example/main.dart';

import 'uvccamera_widget.dart';

class UvcCameraDeviceScreen extends StatefulWidget {
  final UvcCameraDevice device;
  final String appId;

  const UvcCameraDeviceScreen({super.key, required this.appId, required this.device});

  @override
  State<UvcCameraDeviceScreen> createState() => _UvcCameraDeviceScreenState();
}

class _UvcCameraDeviceScreenState extends State<UvcCameraDeviceScreen> {
  UvcCameraDevice get device => widget.device;

  String get appId => widget.appId;
  AgoraService agoraService = AgoraService();

  @override
  void initState() {
    agoraService.initializeAgora(
      appId: appId,
      token: agoraToken,
      channelName: "main-channel",
      uid: 0,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: ListView(
        children: [
          UvcCameraWidget(device: device, agoraEngine: agoraService.engine),
          AgoraVideoView(
            controller: VideoViewController.remote(
                rtcEngine: agoraService.engine, canvas: VideoCanvas(uid: 12), connection: RtcConnection()),
          ),
        ],
      ),
    );
  }
}
