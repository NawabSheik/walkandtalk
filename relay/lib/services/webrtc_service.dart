import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCService {
  late IO.Socket _socket;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  final String signalingUrl;
  String? channelId;
  String? userId;

  WebRTCService({required this.signalingUrl});

  Future<void> initialize(
      {required String userId, required String channelId}) async {
    this.userId = userId;
    this.channelId = channelId;

    _socket = IO.io(signalingUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.on('connect', (_) {
      print('Connected to signaling server');
      _socket.emit('join', {'channelId': channelId, 'userId': userId});
    });

    _socket.on('offer', (data) async {
      print('Received offer');
      await _peerConnection.setRemoteDescription(
        RTCSessionDescription(data['answer'], 'answer'),
      );
      final answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

      _socket.emit('answer', {
        'channelId': channelId,
        'answer': answer.sdp,
        'senderId': userId,
      });
    });

    _socket.on('answer', (data) async {
      print('Received answer');
      await _peerConnection.setRemoteDescription(
        RTCSessionDescription(data['answer'], 'answer'),
      );
    });

    _socket.on('candidate', (data) async {
      print('Received ICE candidate');
      final candidate = RTCIceCandidate(data['candidate']['candidate'],
          data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']);
      await _peerConnection.addCandidate(candidate);
    });

    await _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true});
    _localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, _localStream);
    });

    _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      print('Sending ICE Candidate');
      _socket.emit('candidate', {
        'channelId': channelId,
        'candidate': candidate.toMap(),
        'senderId': userId,
      });
    };

    _peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print('Remote track added');
      }
    };
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);

    _socket.emit('offer', {
      'channelId': channelId,
      'offer': offer.sdp,
      'senderId': userId,
    });   
  }
  
  MediaStream get localStream => _localStream;

    void dispose(){
      _peerConnection.close();
      _localStream.dispose();
      _socket.disconnect();
    }
}
