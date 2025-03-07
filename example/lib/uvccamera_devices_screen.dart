import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';

import 'uvccamera_device_screen.dart';

class UvcCameraDevicesScreen extends StatefulWidget {
  const UvcCameraDevicesScreen({super.key});

  @override
  State<UvcCameraDevicesScreen> createState() => _UvcCameraDevicesScreenState();
}

class _UvcCameraDevicesScreenState extends State<UvcCameraDevicesScreen> {
  bool _isSupported = false;
  StreamSubscription<UvcCameraDeviceEvent>? _deviceEventSubscription;
  final Map<String, UvcCameraDevice> _devices = {};
  final TextEditingController appIdController = TextEditingController();

  // List of permissions required
  final List<Permission> _permissions = [
    Permission.phone,
    Permission.microphone,
    Permission.camera,
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      appIdController.text = "1495a5c75a024f05afe291aa0b5ee5f8";
    }

    UvcCamera.isSupported().then((value) {
      setState(() {
        _isSupported = value;
      });
    });

    _deviceEventSubscription = UvcCamera.deviceEventStream.listen((event) {
      setState(() {
        if (event.type == UvcCameraDeviceEventType.attached) {
          _devices[event.device.name] = event.device;
        } else if (event.type == UvcCameraDeviceEventType.detached) {
          _devices.remove(event.device.name);
        }
      });
    });

    UvcCamera.getDevices().then((devices) {
      setState(() {
        _devices.addAll(devices);
      });
    });
  }

  @override
  void dispose() {
    _deviceEventSubscription?.cancel();
    _deviceEventSubscription = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return const Center(
        child: Text(
          'UVC Camera is not supported on this device.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Text(
          'No UVC devices connected.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: _devices.values.map((device) {
              return ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(device.name),
                subtitle: Text('Vendor ID: ${device.vendorId}, Product ID: ${device.productId}'),
                onTap: () {
                  onDeviceSelected(device);
                },
              );
            }).toList(),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: appIdController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter agora appID',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(80),
          child: ElevatedButton(
              onPressed: _devices.values.isEmpty
                  ? null
                  : () {
                      onDeviceSelected(_devices.values.toList()[0]);
                    },
              child: Text("Submit")),
        )
      ],
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Missing App ID'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enter Agora app Id'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void onDeviceSelected(UvcCameraDevice device) {
    if (appIdController.text.isEmpty) {
      _showMyDialog();
      return;
    }

    _requestPermissions(device);
    /*Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UvcCameraDeviceScreen(device: device, appId: appIdController.text),
      ),
    );*/
  }

  // Function to request permissions
  Future<void> _requestPermissions(UvcCameraDevice device) async {
    Map<Permission, PermissionStatus> statuses = await _permissions.request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      _navigateToNextScreen(device);
    } else {
      _showDeniedPermissionsDialog(device);
    }
  }

  void _navigateToNextScreen(UvcCameraDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UvcCameraDeviceScreen(device: device, appId: appIdController.text),
      ),
    );
  }

  // Show alert if permissions are denied
  void _showDeniedPermissionsDialog(UvcCameraDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permissions Required"),
        content: Text("All permissions must be granted to proceed."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _requestPermissions(device); // Request permissions again
            },
            child: Text("Retry"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // Open settings if permissions are permanently denied
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }
}
