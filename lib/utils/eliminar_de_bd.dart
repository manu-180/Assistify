import 'dart:convert';

import 'package:http/http.dart' as http;

class EliminarDeSupabase {
  Future<void> eliminarUsuario(String uid) async {
    final response = await http.post(
      Uri.parse('https://backend-suscripciones.onrender.com/eliminar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );

    if (response.statusCode == 200) {
      print('✅ Usuario eliminado correctamente');
    } else {
      print('❌ Error al eliminar usuario: ${response.body}');
    }
  }
}
