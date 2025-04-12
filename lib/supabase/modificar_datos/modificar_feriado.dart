import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';

class ModificarFeriado {
  static Future<void> cambiarFeriado({
    required int idClase,
    required bool nuevoValor,
  }) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    await supabase
        .from(taller)
        .update({'feriado': nuevoValor}).eq('id', idClase);
  }
}
