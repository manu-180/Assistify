import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';

class ResetClases {

  Future<void> reset() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(supabase: supabase, clasesTable: taller, usuariosTable: "usuarios").obtenerClases();

    for(final clase in clases){
      await supabase.from(taller).update({"mails": []}).eq("id", clase.id);
      await supabase.from(taller).update({"espera": []}).eq("id", clase.id);

    }
  }
  
}