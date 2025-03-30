import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class ObtenerMes {
  Future<int> obtenerMes() async {
    try {
      // Obtener usuario activo
      final usuarioActivo = Supabase.instance.client.auth.currentUser;
      if (usuarioActivo == null) {
        throw Exception("Usuario no autenticado");
      }

      // Obtener el taller del usuario
      final taller = await ObtenerTaller().retornarTaller(usuarioActivo.id);

      // Consultar el mes en la base de datos
      final data = await supabase.from(taller).select("mes").limit(1).single();

      return data["mes"];
    } catch (e) {
      return DateTime.now().month;
    }
  }
}
