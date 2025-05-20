import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_mes.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';

class EliminarClase {
  Future<void> eliminarClase(int id) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    await supabase.from(taller).delete().eq('id', id);
  }

  Future<void> eliminarMuchasClases({
    required String dia,
    required String hora,
  }) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final mesActual = await ObtenerMes().obtenerMes();

    await supabase.from(taller).delete().match({
      'dia': dia,
      'hora': hora,
      'mes': mesActual,
    });
  }
}
