import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class CreatedAtUser {
  Future<DateTime> retornarCreatedAt() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final users = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerUsuarios();

    for (final user in users) {
      if (user.userUid == usuarioActivo.id) {
        return user.createdAt;
      }
    }
    return DateTime.now();
  }
}
