import 'package:supabase_flutter/supabase_flutter.dart';

class AlMenosUnaClase {
  final supabase = Supabase.instance.client;

  Future<bool> tallerTieneDatos() async {
  final supabase = Supabase.instance.client;
  final usuarioActivo = supabase.auth.currentUser;
  final taller = usuarioActivo!.userMetadata?['taller'];

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
