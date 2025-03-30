import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class IsSubscripto {
  Future<bool> subscripto() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final subsriptos = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerSubscriptos();

    for (final sub in subsriptos) {
      if (sub.userId == usuarioActivo.id) {
        return sub.isActive;
      }
    }
    return false;
  }
}
