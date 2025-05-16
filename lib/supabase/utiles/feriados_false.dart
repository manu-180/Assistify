import 'package:taller_ceramica/supabase/supabase_barril.dart';

class FeriadosFalse {

  Future<void> feriadosFalse() async {

    final usuarioActivo = Supabase.instance.client.auth.currentUser;

    await Supabase.instance.client

    .from(usuarioActivo!.userMetadata?['taller'])
    .update({'feriado': false})
    .neq('feriado', false); // solo las que no están en false

  }
}
