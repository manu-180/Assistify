import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';

class ModificarCredito {
  Future<bool> agregarCreditoUsuario(String user) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    for (final usuario in data) {
      if (usuario.fullname == user) {
        var creditosActualmente = usuario.clasesDisponibles ;
        creditosActualmente += 1;
        await supabase.from('usuarios').update(
            {'clases_disponibles': creditosActualmente}).eq('id', usuario.id);
        ModificarAlertTrigger().resetearAlertTrigger(usuario.fullname);
      }
    }

    return true;
  }

  Future<bool> removerCreditoUsuario(String user) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    for (final usuario in data) {
      if (usuario.fullname == user) {
        var creditosActualmente = usuario.clasesDisponibles ;
        creditosActualmente -= 1;
        if (usuario.clasesDisponibles > 0) {
          await supabase.from('usuarios').update(
              {'clases_disponibles': creditosActualmente}).eq('id', usuario.id);
          ModificarAlertTrigger().resetearAlertTrigger(usuario.fullname);
        }
      }
    }

    return true;
  }
}
