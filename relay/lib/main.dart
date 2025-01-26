import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/api_service.dart';

void main() => runApp(MyApp());

// Fill in the app ID obtained from the Agora console
const appId = "a7648bdf33064b6992a305f1ea1767e3";

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing Agora...');
    initAgora("6795fe3e3f07f0a3a2ab4671", "6795fd2cf2e0361a0ce441b6");
  }

  // Initialize Agora
  Future<void> initAgora(String channelId, String userId) async {
    try {
      debugPrint('Fetching token and channel information...');
      final data = await fetchTokenAndChannel(channelId, userId);

      final String token = data['token'];
      final String channelName = data['channelName'];
      debugPrint('Token: $token');
      debugPrint('Channel Name: $channelName');

      // Request microphone permission
      debugPrint('Requesting microphone permission...');
      final permissionStatus = await [Permission.microphone].request();
      if (!permissionStatus[Permission.microphone]!.isGranted) {
        debugPrint('Microphone permission not granted');
        return;
      }
      debugPrint('Microphone permission granted');

      // Create an RtcEngine instance
      debugPrint('Creating Agora engine...');
      _engine = await createAgoraRtcEngine();

      // Initialize the Agora engine
      debugPrint('Initializing Agora engine...');
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      debugPrint('Registering event handlers...');
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Local user joined successfully: UID = ${connection.localUid}');
            setState(() {
              _localUserJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: UID = $remoteUid');
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user went offline: UID = $remoteUid');
            setState(() {
              _remoteUid = null;
            });
          },
        ),
      );

      // Join a channel
      debugPrint('Joining channel...');
      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: int.parse(userId),
      );
      debugPrint('Successfully joined channel: $channelName');
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('Leaving channel and releasing Agora engine...');
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Voice Call',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora Voice Call'),
        ),
        body: Center(
          child: _localUserJoined
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('You are in the call!'),
                    if (_remoteUid != null)
                      Text('Connected to remote user: UID = $_remoteUid')
                    else
                      const Text('Waiting for remote user to join...'),
                  ],
                )
              : const Text('Joining the call...'),
        ),
      ),
    );
  }
}
