import 'package:assistify/main.dart';

class ObtenerRubro {
  Future<String> rubro(String user) async {
    final data = await supabase
        .from('usuarios')
        .select('rubro')
        .eq('fullname', user)
        .single();

    print("📩 Datos obtenidossssssssss: $data");

    return data["rubro"];
  }
}
