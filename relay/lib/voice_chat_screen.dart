import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import './services/webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermissions() async {
  PermissionStatus microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus.isGranted) {
    return true;
  } else {
    print("Microphone permission denied.");
    return false;
  }
}

class VoiceChatScreen extends StatefulWidget {
  final String signalingUrl;
  final String userId;
  final String channelId;

  VoiceChatScreen({
    required this.signalingUrl,
    required this.userId,
    required this.channelId,
  });

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  late WebRTCService _webRTCService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _isCallinProgress = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();

    bool permissionsGranted = await checkPermissions();
    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Microphone permission is required")),
      );
      return;
    }

    _webRTCService = WebRTCService(signalingUrl: widget.signalingUrl);
    try {
      await _webRTCService.initialize(
          userId: widget.userId, channelId: widget.channelId);
      setState(() {
        _localRenderer.srcObject = _webRTCService.localStream;
        _isInitialized = true;
      });
    } catch (e) {
      print("Error initialzing WebRTC service : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize WebRTC")),
      );
    }
  }

  @override
  void dispose() {
    _webRTCService.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  void _startCall() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("WebRTC not initialized")),
      );
      return;
    }

    setState(() {
      _isCallinProgress = true;
    });

    try {
      await _webRTCService.createOffer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start call')),
      );
    } finally {
      setState(() {
        _isCallinProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Voice Chat')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Channel ID:${widget.channelId}'),
            SizedBox(height: 20),
            if(_localRenderer.srcObject!=null)
              Container(
                width: 200,
                height: 200,
                child:RTCVideoView(_localRenderer),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isCallinProgress?null:_startCall, 
                child: _isCallinProgress ? CircularProgressIndicator():Text('Start Call'),
                )
          ],
        ));
  }
}
