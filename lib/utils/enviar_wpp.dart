import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EnviarWpp {
  void sendWhatsAppMessage(
      String contentSid, String num, List<String> parameters) async {
    print("🟡 Iniciando envío de mensaje por WhatsApp...");

    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");
    print("✅ Variables .env cargadas");

    var apiKeySid = dotenv.env['API_KEY_SID'] ?? '';
    var apiKeySecret = dotenv.env['API_KEY_SECRET'] ?? '';
    var accountSid = dotenv.env['ACCOUNT_SID'] ?? '';

    print("🔑 SID: $apiKeySid");
    print("🔐 Secret presente: ${apiKeySecret.isNotEmpty}");
    print("🧾 Account SID: $accountSid");

    final uri = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');
    print("📡 URL: $uri");

    const fromWhatsappNumber = 'whatsapp:+5491125303794';
    print("📲 From: $fromWhatsappNumber");
    print("📞 To: $num");

    var contentVariables = jsonEncode({
      "1": parameters.isNotEmpty ? parameters[0] : "",
      "2": parameters.length > 1 ? parameters[1] : "",
      "3": parameters.length > 2 ? parameters[2] : "",
      "4": parameters.length > 3 ? parameters[3] : "",
      "5": parameters.length > 4 ? parameters[4] : "",
    });

    print("📝 ContentSid: $contentSid");
    print("🧩 ContentVariables: $contentVariables");

    var body = {
      'From': fromWhatsappNumber,
      'To': num,
      'ContentSid': contentSid,
      'ContentVariables': contentVariables,
    };

    print("📦 Cuerpo del POST:");
    body.forEach((k, v) => print("   $k: $v"));

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$apiKeySid:$apiKeySecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      print("📬 Código de estado: ${response.statusCode}");
      print("📩 Body: ${response.body}");

      if (response.statusCode == 201) {
        print("✅ Mensaje enviado correctamente");
      } else {
        print("❌ Error al enviar mensaje: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Excepción al enviar mensaje: $e");
    }
  }
}
