import 'package:taller_ceramica/main.dart';

class ObtenerClasesDisponibles {
  Future<int> clasesDisponibles(String user) async {
    final data = await supabase
        .from('usuarios')
        .select('clases_disponibles')
        .eq('fullname', user)
        .single();

    return data["clases_disponibles"];
  }
}
