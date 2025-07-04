import 'package:assistify/main.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';

class ActualizarElMes {
  Future<void> actualizarMes(int mes) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerClases();

    for (final clase in clases) {
      await supabase.from(taller).update({'mes': mes}).eq('id', clase.id);
    }
  }
}
