import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';


class ObtenerLugarDisponible {
  Future<int?> obtenerLugarDisponible(int id) async {
    final supabase = Supabase.instance.client;
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final response = await supabase
        .from(taller) // Reemplaza con el nombre real de tu tabla
        .select('lugar_disponible')
        .eq('id', id)
        .single(); // Obtiene un solo resultado

    if (response['lugar_disponible'] != null) {
      return response['lugar_disponible'] as int; // Devuelve el número de lugares disponibles
    }

    return null; // En caso de que no se encuentre el dato
  }
}

