import 'dart:async';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';
import 'package:uvccamera_example/main.dart';

class UvcCameraWidget extends StatefulWidget {
  final UvcCameraDevice device;

  const UvcCameraWidget({super.key, required this.device});

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
  String _log = '';

  bool isStreaming = false;
  late final RtcEngine _engine;
  bool isJoined = false;
  int? remoteUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _initializeAgora();

    _attach();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _detach(force: true);

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

            _cameraController!.cameraStreamEvents.listen(
              (Uint8List event) {
             //   print("cameraStreamEvents: $event");

                if (isStreaming) {
                 // pushFrameToAgora(event, 1280, 720);
                }
              },
            );
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

    _isAttached = true;
  }

  void pushFrameToAgora(Uint8List frameData, int width, int height) async {
    VideoPixelFormat format = VideoPixelFormat.videoPixelNv21;
    print("pushFrameToAgora: here");
    await _engine.getMediaEngine().pushVideoFrame(
        frame: ExternalVideoFrame(
            type: VideoBufferType.videoBufferRawData,
            format: format,
            buffer: frameData,
            stride: width,
            height: height,
            timestamp: DateTime.now().millisecondsSinceEpoch));
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
          return Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: UvcCameraPreview(
                  _cameraController!,
                ),
              ),
              if (isJoined)
                SizedBox(
                  height: 200,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              if (remoteUid != null)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: remoteUid!),
                        connection: const RtcConnection(channelId: "main-channel"),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                      onPressed: () async {
                        if (!isStreaming) {
                          if (_cameraController != null) {
                            await _joinChannel();
                            _startStreaming();
                          }
                        }
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

  Future<void> _initializeAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            isJoined = true;
          });
          print("Local user joined: ${connection.localUid}");
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            remoteUid = uid;
          });
          print("Remote user joined: $uid");
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          setState(() {
            remoteUid = null;
          });
          print("Remote user left: $uid");
        },
      ),
    );

    await _engine.getMediaEngine().setExternalVideoSource(enabled: true, useTexture: true);

    await _engine.enableVideo();
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token:
          "007eJxTYEistP/6cllgqpqhrU/v731fDU7wFCo95X3w+tXcJQfn6M5VYDA0sTRNNE02N000MDJJMzBNTEs1sjRMTDRIMk1NNU2zmB54Ir0hkJHh4/yjzIwMEAji8zDkJmbm6SZnJOblpeYwMAAA85clCw==",
      channelId: "main-channel",
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    setState(() {
      isJoined = false;
      remoteUid = null;
    });
  }

  Future<void> _startStreaming() async {
    // print("_startStreaming textureId: $textureId");
    setState(() {
      isStreaming = true;
    });

    if (_cameraController == null || _cameraController!.textureId == null) {
      print("Error: Texture ID is null");
      return;
    }

    print("USB Camera textureId: ${_cameraController!.textureId}");



    await _engine.getMediaEngine().pushVideoFrame(
          frame: ExternalVideoFrame(
            type: VideoBufferType.videoBufferTexture,
            format: VideoPixelFormat.videoPixelNv21,
            textureId: _cameraController!.textureId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            stride: 1280,
            height: 720,

          ),
        );

    print("Started streaming video from texture ID");


    /*final cameraStreamEventChannel = EventChannel('uvccamera/frame_stream');
     cameraStreamEventChannel.receiveBroadcastStream().listen((event) {
       print("cameraStreamEventChannel");
     },);
*/

  }
}
