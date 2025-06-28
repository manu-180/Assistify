import 'package:assistify/main.dart';

class ObtenerNombre {
  Future<String> fullname(String user) async {
    final data = await supabase
        .from('usuarios')
        .select('rubro')
        .eq('fullname', user)
        .single();

    print("📩 Datos obtenidossssssssss: $data");

    return data["rubro"];
  }
}
