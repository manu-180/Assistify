import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taller_ceramica/utils/capitalize.dart';

Future<String?> crearUsuarioAdmin({
  required String email,
  required String password,
  required String fullname,
  required String telefono,
  required String rubro,
  required String taller,
}) async {
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final serviceRoleKey = dotenv.env['SERVICE_ROLE_KEY']!;

  final uri = Uri.parse('$supabaseUrl/auth/v1/admin/users');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    },
    body: json.encode({
      "email": email,
      "password": password,
      "user_metadata": {
        'fullname': Capitalize().capitalize(fullname),
    "rubro": rubro,
    "taller": Capitalize().capitalize(taller),
    "telefono": telefono,
    "admin": false,
    "created_at": DateTime.now().toIso8601String(),
      },
      "email_confirm": true,
    }),
  );

  print("📬 Código de estado: ${response.statusCode}");
  print("📩 Body: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    final body = json.decode(response.body);

    // Puede ser null si ya existe
    if (body['id'] != null) {
      print("✅ Usuario creado con ID: ${body['id']}");
      return body['id'];
    } else {
      print("⚠️ Usuario ya existe o sin ID devuelto");
      return null;
    }
  } else {
    print("❌ Error al crear el usuario: ${response.body}");
    return null;
  }
}
