import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class RedirigirUsuarioAlTaller {
  Future<void> redirigirUsuario(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception("No hay usuario activo");
      }

      final taller = await ObtenerTaller().retornarTaller(user.id);

      if (taller.isEmpty) {
        throw Exception("Taller desconocido (está vacío)");
      }

      if (context.mounted) {
        context.go("/home/$taller");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al redirigir: $e")),
        );
      }
    }
  }
}
