import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/main.dart';

class ModificarLugarDisponible {
  Future<bool> agregarLugarDisponible(int id) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();

    for (final clase in data) {
      if (clase.id == id) {
        var lugarDisponibleActualmente = clase.lugaresDisponibles;
        lugarDisponibleActualmente += 1;
        await supabase
            .from(taller)
            .update({'lugar_disponible': lugarDisponibleActualmente}).eq(
                'id', clase.id);
      }
    }

    return true;
  }

  Future<bool> removerLugarDisponible(int id) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerClases();

    for (final clase in data) {
      if (clase.id == id) {
        var lugarDisponibleActualmente = clase.lugaresDisponibles;
        lugarDisponibleActualmente -= 1;
        await supabase
            .from(taller)
            .update({'lugar_disponible': lugarDisponibleActualmente}).eq(
                'id', clase.id);
      }
    }

    return true;
  }
}
