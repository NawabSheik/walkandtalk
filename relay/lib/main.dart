import 'package:flutter/material.dart';
import 'voice_chat_screen.dart'; // Import the VoiceChatScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walkie Talkie App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomeScreen(), // Set a home screen (can be VoiceChatScreen directly)
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _channelIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Walkie Talkie App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _channelIdController,
              decoration: InputDecoration(
                labelText: 'Channel ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_userIdController.text.isNotEmpty &&
                    _channelIdController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceChatScreen(
                        signalingUrl: "ws://localhost:3000", // Backend URL
                        userId: _userIdController.text,
                        channelId: _channelIdController.text,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: Text('Join Voice Chat'),
            ),
          ],
        ),
      ),
    );
  }
}