import 'package:supabase_flutter/supabase_flutter.dart';

class ObtenerNumero{
Future<String?> obtenerTelefonoAdmin() async {
  final usuarioActivo = Supabase.instance.client.auth.currentUser;

  final taller = usuarioActivo?.userMetadata?['taller'];

  if (taller == null) return null;

  final respuesta = await Supabase.instance.client
      .from('usuarios')
      .select('telefono')
      .eq('taller', taller)
      .eq('admin', true)
      .limit(1)
      .maybeSingle();

  return respuesta?['telefono'];
}


Future<String?> obtenerTelefonoPorNombre(String user) async {
  final respuesta = await Supabase.instance.client
      .from('usuarios')
      .select('telefono')
      .eq('fullname', user)
      .limit(1)
      .maybeSingle();

  return respuesta?['telefono'];
}


}

