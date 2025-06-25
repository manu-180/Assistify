import 'package:assistify/main.dart';

class ObtenerNombreConTelefono {
  Future<String> nombre(String telefono) async {
    try {
      final data = await supabase
          .from('usuarios')
          .select('fullname')
          .eq('telefono', telefono)
          .single();

      print("✅ LA DATA ES $data");

      // Si encontró fullname, lo devuelve
      return data["fullname"] ?? telefono;
    } catch (e) {
      print("❌ No se encontró el teléfono o error: $e");

      // Si hubo error o no encontró, devuelve el mismo número
      return telefono;
    }
  }
}
