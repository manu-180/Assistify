import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';

class ObtenerFeriado {
  Future<bool> obtenerFeriado(int id) async {
    
      final usuarioActivo = Supabase.instance.client.auth.currentUser;
      if (usuarioActivo == null) {
        throw Exception("Usuario no autenticado");
      }

      final taller = await ObtenerTaller().retornarTaller(usuarioActivo.id);

      final data = await supabase
        .from(taller)
        .select('feriado')
        .eq('id', id)
        .single();

    return data["feriado"];
  
  }
}
