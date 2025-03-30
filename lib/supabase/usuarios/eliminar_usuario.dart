import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';

class EliminarUsuario {
  Future<void> eliminarDeBaseDatos(int userId) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final dataClases = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();
    final dataUsuarios = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    var user = "";

    await supabase.from('usuarios').delete().eq('id', userId);

    for (var usuario in dataUsuarios) {
      if (usuario.id == userId) {
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
