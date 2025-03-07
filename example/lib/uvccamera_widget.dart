import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

class UvcCameraWidget extends StatefulWidget {
  final UvcCameraDevice device;
  final String appId;

  const UvcCameraWidget({super.key, required this.appId, required this.device});

  @override
  State<UvcCameraWidget> createState() => _UvcCameraWidgetState();
}

class _UvcCameraWidgetState extends State<UvcCameraWidget> with WidgetsBindingObserver {
  bool _isAttached = false;
  bool _hasDevicePermission = false;
  bool _hasCameraPermission = false;
  bool _isDeviceAttached = false;
  bool _isDeviceConnected = false;
  UvcCameraController? _cameraController;
  Future<void>? _cameraControllerInitializeFuture;
  StreamSubscription<UvcCameraErrorEvent>? _errorEventSubscription;
  StreamSubscription<UvcCameraStatusEvent>? _statusEventSubscription;
  StreamSubscription<UvcCameraButtonEvent>? _buttonEventSubscription;
  StreamSubscription<UvcCameraDeviceEvent>? _deviceEventSubscription;
  StreamSubscription<UvcAgoraEvent>? _agoraEventSubscription;
  String _log = '';

  bool isStreaming = false;

  int? _remoteUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _attach();

    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _detach(force: true);
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _attach();
    } else if (state == AppLifecycleState.paused) {
      _detach();
    }
  }

  void _attach({bool force = false}) {
    if (_isAttached && !force) {
      return;
    }

    UvcCamera.getDevices().then((devices) {
      if (!devices.containsKey(widget.device.name)) {
        return;
      }

      setState(() {
        _isDeviceAttached = true;
      });

      _requestPermissions();
    });

    _deviceEventSubscription = UvcCamera.deviceEventStream.listen((event) {
      if (event.device.name != widget.device.name) {
        return;
      }

      if (event.type == UvcCameraDeviceEventType.attached && !_isDeviceAttached) {
        // NOTE: Requesting UVC device permission will trigger connection request
        _requestPermissions();
      }

      setState(() {
        if (event.type == UvcCameraDeviceEventType.attached) {
          // _hasCameraPermission - maybe
          // _hasDevicePermission - maybe
          _isDeviceAttached = true;
          _isDeviceConnected = false;
        } else if (event.type == UvcCameraDeviceEventType.detached) {
          _hasCameraPermission = false;
          _hasDevicePermission = false;
          _isDeviceAttached = false;
          _isDeviceConnected = false;
        } else if (event.type == UvcCameraDeviceEventType.connected) {
          _hasCameraPermission = true;
          _hasDevicePermission = true;
          _isDeviceAttached = true;
          _isDeviceConnected = true;

          _log = '';

          _cameraController = UvcCameraController(
            device: widget.device,
          );
          _cameraControllerInitializeFuture = _cameraController!.initialize().then((_) async {
            _errorEventSubscription = _cameraController!.cameraErrorEvents.listen((event) {
              setState(() {
                _log = 'error: ${event.error}\n$_log';
              });

              if (event.error.type == UvcCameraErrorType.previewInterrupted) {
                _detach();
                _attach();
              }
            });

            _statusEventSubscription = _cameraController!.cameraStatusEvents.listen((event) {
              setState(() {
                _log = 'status: ${event.payload}\n$_log';
              });
            });

            _buttonEventSubscription = _cameraController!.cameraButtonEvents.listen((event) {
              setState(() {
                _log = 'btn(${event.button}): ${event.state}\n$_log';
              });
            });
          });
        } else if (event.type == UvcCameraDeviceEventType.disconnected) {
          _hasCameraPermission = false;
          _hasDevicePermission = false;
          // _isDeviceAttached - maybe?
          _isDeviceConnected = false;

          _buttonEventSubscription?.cancel();
          _buttonEventSubscription = null;

          _statusEventSubscription?.cancel();
          _statusEventSubscription = null;

          _errorEventSubscription?.cancel();
          _errorEventSubscription = null;

          _cameraController?.dispose();
          _cameraController = null;
          _cameraControllerInitializeFuture = null;

          _log = '';
        }
      });
    });

    _agoraEventSubscription = UvcCamera.agoraEventStream.listen(
      (event) {
        print("agoraEventStream: $event");

        if (event.event == "onUserJoined") {
          setState(() {
            _remoteUid = event.uid;
          });
        } else if (event.event == "onUserOffline") {
          setState(() {
            _remoteUid = null; // Remove the remote video view
          });
        }
      },
    );
    _isAttached = true;
  }

  void _detach({bool force = false}) {
    if (!_isAttached && !force) {
      return;
    }

    _hasDevicePermission = false;
    _hasCameraPermission = false;
    _isDeviceAttached = false;
    _isDeviceConnected = false;

    _buttonEventSubscription?.cancel();
    _buttonEventSubscription = null;

    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    _cameraController?.dispose();
    _cameraController = null;
    _cameraControllerInitializeFuture = null;

    _deviceEventSubscription?.cancel();
    _deviceEventSubscription = null;

    _agoraEventSubscription?.cancel();
    _agoraEventSubscription = null;

    _isAttached = false;
  }

  Future<void> _requestPermissions() async {
    final hasCameraPermission = await _requestCameraPermission().then((value) {
      setState(() {
        _hasCameraPermission = value;
      });

      return value;
    });

    // NOTE: Requesting UVC device permission can be made only after camera permission is granted
    if (!hasCameraPermission) {
      return;
    }

    _requestDevicePermission().then((value) {
      setState(() {
        _hasDevicePermission = value;
      });

      return value;
    });
  }

  Future<bool> _requestDevicePermission() async {
    final devicePermissionStatus = await UvcCamera.requestDevicePermission(widget.device);
    return devicePermissionStatus;
  }

  Future<bool> _requestCameraPermission() async {
    var cameraPermissionStatus = await Permission.camera.status;
    if (cameraPermissionStatus.isGranted) {
      return true;
    } else if (cameraPermissionStatus.isDenied || cameraPermissionStatus.isRestricted) {
      cameraPermissionStatus = await Permission.camera.request();
      return cameraPermissionStatus.isGranted;
    } else {
      // NOTE: Permission is permanently denied
      return false;
    }
  }

  Future<void> _startVideoRecording(UvcCameraMode videoRecordingMode) async {
    await _cameraController!.startVideoRecording(videoRecordingMode);
  }

  Future<void> _takePicture() async {
    final XFile outputFile = await _cameraController!.takePicture();

    outputFile.length().then((length) {
      setState(() {
        _log = 'image file: ${outputFile.path} ($length bytes)\n$_log';
      });
    });
  }

  Future<void> _stopVideoRecording() async {
    final XFile outputFile = await _cameraController!.stopVideoRecording();

    outputFile.length().then((length) {
      setState(() {
        _log = 'video file: ${outputFile.path} ($length bytes)\n$_log';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeviceAttached) {
      return Center(
        child: Text(
          'Device is not attached',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    if (!_hasCameraPermission) {
      return Center(
        child: Text(
          'Camera permission is not granted',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    if (!_hasDevicePermission) {
      return Center(
        child: Text(
          'Device permission is not granted',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    if (!_isDeviceConnected) {
      return Center(
        child: Text(
          'Device is not connected',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _cameraControllerInitializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: UvcCameraPreview(
                  _cameraController!,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _log,
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Courier',
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 160,
                  height: 200,
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black54, width: 1)),
                  child: _remoteUid != null ? _buildAgoraRemoteView(_remoteUid!) : _buildWaitingScreen(),
                ),
              ),
              /*SizedBox(
                height: 200,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _agoraEngine,
                    canvas: VideoCanvas(uid: 0),
                  ),
                ),
              ),
              if (isRemoteJoined)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 100,
                    height: 100,
                    child: AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraEngine,
                        canvas: VideoCanvas(uid: remoteUid),
                        connection: RtcConnection(localUid: 0,channelId: "main-channel")
                      ),
                    ),
                  ),
                ),*/
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ElevatedButton(
                      onPressed: () {
                        if (!isStreaming) {
                          isStreaming = true;
                          _cameraController?.initializeAgora(
                              widget.appId,
                              "007eJxTYNjOcvXN58URuQyTrrLoG9+onp950zCF71iXaD/v88QyuTMKDIYmlqaJpsnmpokGRiZpBqaJaalGloaJiQZJpqmppmkWfGdOpTcEMjJ4mD5mYWSAQBCfhyE3MTNPNzkjMS8vNYeBAQA9CiIb",
                              "main-channel",
                              0); //pass actual token, channel and uid here
                        } else {
                          isStreaming = false;
                          _cameraController?.stopStream();
                        }
                        Future.delayed(Duration(seconds: 1)).then(
                          (value) {
                            if (mounted) setState(() {});
                          },
                        );
                      },
                      child: Text(isStreaming ? "Stop Stream" : "Start stream on Agora")),
                ),
              )
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Text(
        "Waiting for remote user...",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildAgoraRemoteView(int uid) {
    // This is used in the platform side to register the view
    const String viewType = 'agora_remote_view';

    // Pass parameters to the platform side
    final Map<String, dynamic> creationParams = <String, dynamic>{"uid": uid};

    // Use PlatformViewLink for Hybrid Composition (preferred on Android)
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
