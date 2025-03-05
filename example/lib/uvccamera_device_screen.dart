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

  @override
  void initState() {

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
          UvcCameraWidget(device: device),

          /*SizedBox(
            height: 200,
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                  rtcEngine: agoraService!.engine,
                  canvas: VideoCanvas(uid: 121),
                  connection: RtcConnection(channelId: "main-channel")),
            ),
          ),*/
        ],
      ),
    );
  }


}
