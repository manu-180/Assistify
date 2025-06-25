import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:assistify/supabase/obtener_datos/obtener_nombre_con_telefono.dart';

class TwilioService {
  final apiKeySid = dotenv.env['API_KEY_SID'] ?? '';
  final apiKeySecret = dotenv.env['API_KEY_SECRET'] ?? '';
  final accountSid = dotenv.env['ACCOUNT_SID'] ?? '';

  String basicAuthHeader() {
    final credentials = base64Encode(utf8.encode('$apiKeySid:$apiKeySecret'));
    return 'Basic $credentials';
  }

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';

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
        'Authorization': basicAuthHeader(),
      },
    );

    print("🧪 STATUS: ${res.statusCode}");
    print("📦 BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('Error al cargar conversaciones');
    }

    final data = jsonDecode(res.body);
    final List<Map<String, dynamic>> conversations =
        List<Map<String, dynamic>>.from(data['conversations']);

    // 🚀 Enriquecer con nombre del participante
    for (final convo in conversations) {
      final sid = convo['sid'];
      final participantName = await fetchFirstParticipantIdentity(sid);

      convo['user_name'] = participantName;
    }

    return conversations;
  }

  Future<String?> fetchFirstParticipantIdentity(String conversationSid) async {
    final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';

    final url =
        'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$conversationSid/Participants';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
      },
    );

    print("👤 PARTICIPANTS STATUS: ${res.statusCode}");
    print("👤 BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final participants =
          List<Map<String, dynamic>>.from(data['participants']);

      if (participants.isNotEmpty) {
        final p = participants.first;

        final rawAttributes = p['attributes'];
        try {
          if (rawAttributes != null &&
              rawAttributes is String &&
              rawAttributes.isNotEmpty) {
            final parsed = jsonDecode(rawAttributes);
            if (parsed['name'] != null &&
                parsed['name'].toString().isNotEmpty) {
              return parsed['name'];
            }
          }
        } catch (e) {
          print('⚠️ Error al parsear atributos: $e');
        }

        final address = p['messaging_binding']?['address'];
        if (address != null && address.toString().startsWith('whatsapp:+549')) {
          return ObtenerNombreConTelefono()
              .nombre(address.toString().replaceFirst('whatsapp:+549', ''));
        }

        return ObtenerNombreConTelefono().nombre(address!.toString());
      }
    }

    return 'Desconocido';
  }

  Future<void> debugPrintParticipants(String conversationSid) async {
    final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';

    final url =
        'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$conversationSid/Participants';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
      },
    );

    print("👤 PARTICIPANTS STATUS: ${res.statusCode}");
    print("👤 BODY: ${res.body}");
  }

  Future<String> getMediaUrl(String mediaSid) async {
    final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';

    final url =
        'https://mcs.us1.twilio.com/v1/Services/$serviceSid/Media/$mediaSid';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['links']['content_direct_temporary']; // URL real al archivo
    } else {
      throw Exception('No se pudo obtener la URL del audio');
    }
  }

  Future<void> updateParticipantAttributes(String conversationSid,
      String participantSid, Map<String, dynamic> attributes) async {
    final url =
        'https://conversations.twilio.com/v1/Conversations/$conversationSid/Participants/$participantSid';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'Attributes': jsonEncode(attributes),
      },
    );

    print("🔧 UPDATE ATTRIBUTES STATUS: ${response.statusCode}");
    print("🔧 BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('No se pudieron actualizar los atributos');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String sid) async {
    final serviceSid = dotenv.env['CONVERSATION_SERVICE_SID'] ?? '';
    final url =
        'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$sid/Messages';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
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
    final url =
        'https://conversations.twilio.com/v1/Services/$serviceSid/Conversations/$sid/Messages';

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuthHeader(),
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
