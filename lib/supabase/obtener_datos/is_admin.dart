import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/main.dart';

class IsAdmin {
  Future<bool> admin() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    if (usuarioActivo == null) {
      return false;
    }

    final taller = await ObtenerTaller().retornarTaller(usuarioActivo.id);
    final users = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerUsuarios();

    for (final user in users) {
      if (user.userUid == usuarioActivo.id) {
        return user.admin;
      }
    }
    return false;
  }
}
