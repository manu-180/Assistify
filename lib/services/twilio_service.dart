import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TwilioService {
  final apiKeySid = dotenv.env['API_KEY_SID'] ?? '';
  final apiKeySecret = dotenv.env['API_KEY_SECRET'] ?? '';
  final accountSid = dotenv.env['ACCOUNT_SID'] ?? '';

  String _basicAuthHeader() {
    final credentials = base64Encode(utf8.encode('$apiKeySid:$apiKeySecret'));
    return 'Basic $credentials';
  }

  Future<List<Map<String, dynamic>>> fetchConversations() async {
  final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? ''; // ejemplo: IS9...
  
  final uri = Uri.https(
    'conversations.twilio.com',
    '/v1/Services/$serviceSid/Conversations',
    {
      'PageSize': '50',
    },
  );

  final res = await http.get(
    uri,
    headers: {
      'Authorization': _basicAuthHeader(),
    },
  );

  print("🧪 STATUS: ${res.statusCode}");
  print("📦 BODY: ${res.body}");

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final conversations = List<Map<String, dynamic>>.from(data['conversations']);
    print("🔍 Conversaciones encontradas: ${conversations.length}");

    return conversations;
  } else {
    throw Exception('Error al cargar conversaciones');
  }
}



  Future<List<Map<String, dynamic>>> fetchMessages(String sid) async {
  final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';
  final url = 'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$sid/Messages';

  final res = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': _basicAuthHeader(),
    },
  );

  print("🔹 FETCH MESSAGES STATUS: ${res.statusCode}");
  print("🔹 BODY: ${res.body}");

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['messages']);
  } else {
    throw Exception('Error al obtener mensajes');
  }
}


  Future<void> sendMessage(String sid, String text) async {
  final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';
  final url = 'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$sid/Messages';

  final res = await http.post(
    Uri.parse(url),
    headers: {
      'Authorization': _basicAuthHeader(),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'Body': text,
    },
  );

  print("📤 SEND MESSAGE STATUS: ${res.statusCode}");
  print("📤 BODY: ${res.body}");

  if (res.statusCode != 201) {
    throw Exception('No se pudo enviar el mensaje');
  }
}

}
