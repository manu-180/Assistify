import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> verificarSuscripcionConBackend({
  required String purchaseToken,
  required String subscriptionId,
}) async {
  final url = Uri.parse('https://backend-suscripciones.onrender.com/verificar');

  print('🔁 Verificando con backend...');
  print('📦 Token: $purchaseToken');
  print('📦 ID Sub: $subscriptionId');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'purchase_token': purchaseToken,
      'subscription_id': subscriptionId,
    }),
  );

  print('📡 Status backend: ${response.statusCode}');
  print('📬 Body backend: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final activa = data['activa'] == true;
    print('✅ Estado validado desde backend: $activa');
    return activa;
  } else {
    print('❌ Error verificando con backend');
    throw Exception('Error al verificar la suscripción con el backend');
  }
}
