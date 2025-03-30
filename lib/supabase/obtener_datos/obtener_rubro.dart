import 'package:taller_ceramica/main.dart';

class ObtenerRubro {
  Future<String> rubro(String user) async {
    final data = await supabase
        .from('usuarios')
        .select('rubro')
        .eq('fullname', user)
        .single();

    return data["rubro"];
  }
}
