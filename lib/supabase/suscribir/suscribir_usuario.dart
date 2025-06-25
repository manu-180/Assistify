import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assistify/main.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/obtener_datos/obtener_total_info.dart';

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
    required String taller,
  }) async {
    final existing = await supabase
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Actualiza si ya existe
      await supabase.from('subscriptions').update({
        'product_id': productId,
        'purchase_token': purchaseToken,
        'start_date': startDate.toIso8601String(),
        'is_active': isActive,
        'taller': taller,
      }).eq('user_id', userId);
    } else {
      // Inserta si no existe
      await supabase.from('subscriptions').insert({
        'user_id': userId,
        'product_id': productId,
        'purchase_token': purchaseToken,
        'start_date': startDate.toIso8601String(),
        'is_active': isActive,
        'taller': taller,
      });
    }
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
