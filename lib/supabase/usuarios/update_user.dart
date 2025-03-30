import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/main.dart';

class UpdateUser {
  final SupabaseClient supabaseClient;

  UpdateUser(this.supabaseClient);

  Future<void> updateUser(String user, String updateUser) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();

    for (final clase in clases) {
      if (clase.mails.contains(user)) {
        final listUsers = clase.mails;
        listUsers.remove(user);
        listUsers.add(updateUser);
        await supabaseClient
            .from(taller)
            .update({'mails': listUsers}).eq('id', clase.id);
      }
    }
  }

  Future<void> updateTableUser(String userUid, String updateUser) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final users = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    for (final user in users) {
      if (user.userUid == userUid) {
        final newName = updateUser;
        await supabaseClient
            .from('usuarios')
            .update({'fullname': newName}).eq('id', user.id);
      }
    }
  }
}
