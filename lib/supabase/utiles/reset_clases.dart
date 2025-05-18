import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class ResetClases {
  Future<void> reset() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerClases();

    for (final clase in clases) {
      print('🔎 Procesando clase con ID: ${clase.id}');
      await supabase.from(taller).update({
        "mails": [],
        "espera": [],
      }).eq("id", clase.id);
    }
  }
}
