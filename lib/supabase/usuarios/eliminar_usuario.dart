import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/main.dart';

class EliminarUsuario {
  Future<void> eliminarUsuarioAutenticado(String uid) async {
    final response = await http.post(
      Uri.parse('https://backend-suscripciones.onrender.com/eliminar-auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );

    if (response.statusCode == 200) {
      print('✅ Usuario autenticado eliminado correctamente');
    } else {
      print('❌ Error al eliminar usuario autenticado: ${response.body}');
    }
  }

  Future<void> eliminarDeBaseDatos(String uid) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final dataClases = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();
    final dataUsuarios = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    var user = "";

    await supabase.from('usuarios').delete().eq('user_uid', uid);

    for (var usuario in dataUsuarios) {
      if (usuario.userUid == uid) {
        user = usuario.fullname;
      }
    }
    for (var clase in dataClases) {
      if (clase.mails.contains(user)) {
        var alumnos = clase.mails;
        alumnos.remove(user);
        await supabase
            .from(taller)
            .update({'mails': alumnos}).eq('id', clase.id);
        ModificarLugarDisponible().agregarLugarDisponible(clase.id);
      }
    }
  }
}
