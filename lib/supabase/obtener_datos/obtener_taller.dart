import 'package:taller_ceramica/main.dart';

class ObtenerTaller {
  Future<String> retornarTaller(String userUid) async {
    final data = await supabase
        .from("usuarios")
        .select("taller")
        .eq("user_uid", userUid)
        .maybeSingle();

    if (data == null) {
      throw Exception("No se encontró un taller para el usuario especificado.");
    }

    return data["taller"];
  }
}
