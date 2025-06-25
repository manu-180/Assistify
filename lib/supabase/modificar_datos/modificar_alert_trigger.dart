import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/main.dart';

class ModificarAlertTrigger {
  Future<bool> agregarAlertTrigger(String user) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    for (final usuario in data) {
      if (usuario.fullname == user) {
        await supabase
            .from('usuarios')
            .update({'trigger_alert': 1}).eq('id', usuario.id);
      }
    }
    return true;
  }

  Future<bool> resetearAlertTrigger(String user) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    for (final item in data) {
      if (item.fullname == user) {
        await supabase
            .from('usuarios')
            .update({'trigger_alert': 0}).eq('id', item.id);
      }
    }
    return true;
  }
}
