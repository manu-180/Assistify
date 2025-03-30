import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';

class GenerarId {
  Future<int> generarIdUsuario() async {
    final supabase = Supabase.instance.client;

    final respuesta = await supabase
        .from("usuarios")
        .select('id')
        .order("id", ascending: false)
        .limit(1);

    final idUnico = respuesta[0]["id"] + 1;

    return idUnico;

  }

  Future<int> generarIdClase() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final listclase = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();

    if (listclase.isEmpty) {
      return 1;
    }

    listclase.sort((a, b) => a.id.compareTo(b.id));

    for (int i = 0; i < listclase.length - 1; i++) {
      if (listclase[i].id + 1 != listclase[i + 1].id) {
        return listclase[i].id + 1;
      }
    }

    return listclase.last.id + 1;
  }
}

