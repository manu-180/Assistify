import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/utils/encontrar_semana.dart';

class ActualizarSemanas {
  get supabaseClient => null;


  

Future<void> actualizarSemana() async {

  final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
  final supabase = Supabase.instance.client;

    final response = await supabase
        .from(taller) 
        .select('id, fecha');

    for (final data in response) {
       await supabase.from(taller).update({'semana': EncontrarSemana().obtenerSemana(data["fecha"])}).eq('id', data["id"]);
       await supabase.from(taller).update({'lugar_disponible': 5}).eq('id', data["id"]);

    }

    
}

}