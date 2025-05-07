import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';

class AlMenosUnaClase {
  final supabase = Supabase.instance.client;

  Future<bool> tallerTieneDatos() async {
  final supabase = Supabase.instance.client;
  final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

  final response = await supabase
      .from(taller)
      .select()
      .limit(1);

  if (response is List) {
    return response.isNotEmpty;
  } else {
    throw Exception('Error al consultar la tabla $taller.');
  }
}
}
