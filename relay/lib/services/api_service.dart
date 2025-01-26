import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchTokenAndChannel(
    String channelId, String userId) async {
  final url = "http://10.0.2.2/channel/join";
  print(url);
  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "channelId": channelId,
      "userId": userId,
    }),
  );
  print(response);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      "token": data['token'],
      "channelName": data['channel']['name'], // Use the channel name
    };
  } else {
    throw Exception('Failed to fetch token');
  }
}
