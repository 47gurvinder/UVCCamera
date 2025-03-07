import 'package:flutter/material.dart';
import 'package:uvccamera/uvccamera.dart';

import 'uvccamera_widget.dart';

class UvcCameraDeviceScreen extends StatelessWidget {
  final UvcCameraDevice device;
  final String appId;

  const UvcCameraDeviceScreen({super.key, required this.appId, required this.device});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.name),
        ),
        body: Center(
          child: UvcCameraWidget(device: device, appId: appId),
        ),
      ),
    );
  }
}
