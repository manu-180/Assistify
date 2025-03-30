import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';

class SuscribirUsuario {
  final SupabaseClient supabaseClient;

  SuscribirUsuario({required this.supabaseClient});

  /// Función para insertar un nuevo registro en la tabla `subscriptions`
  Future<void> insertSubscription({
    required String userId,
    required String productId,
    required String purchaseToken,
    required DateTime startDate,
    required bool isActive,
  }) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    if (await inSuscription() != "") {
      await supabase.from('subscriptions').update({
        'product_id': productId,
        'purchase_token': purchaseToken,
        'start_date': startDate.toIso8601String(),
        'is_active': isActive,
      }).eq('id', await inSuscription());
      return;
    }
    await supabaseClient.from('subscriptions').insert({
      'user_id': userId,
      'product_id': productId,
      'purchase_token': purchaseToken,
      'start_date': startDate.toIso8601String(),
      'is_active': isActive,
      'taller': taller,
    });
  }

  Future<String> inSuscription() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final subscriptores = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerSubscriptos();

    for (final sub in subscriptores) {
      if (sub.userId == usuarioActivo.id) {
        return sub.id;
      }
    }
    return "";
  }
}
