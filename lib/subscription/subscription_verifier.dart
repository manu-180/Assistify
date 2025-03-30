import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ntp/ntp.dart';
import 'package:taller_ceramica/supabase/obtener_datos/created_at_user.dart';
import 'package:taller_ceramica/supabase/obtener_datos/is_admin.dart';
import 'package:taller_ceramica/supabase/suscribir/is_subscripto.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';

class SubscriptionVerifier {
  static Future<DateTime?> verificarAdminYSuscripcion(
      BuildContext context) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    if (usuarioActivo == null) {
      return null;
    }

    if (usuarioActivo.id == '939d2e1a-13b3-4af0-be54-1a0205581f3b') {
      return null;
    }

    final taller = await ObtenerTaller().retornarTaller(usuarioActivo.id);
    final isAdmin = await IsAdmin().admin();
    final isSubscribed = await IsSubscripto().subscripto();
    final createdAt = await CreatedAtUser().retornarCreatedAt();

    final DateTime createdAtUtc = createdAt.toUtc();
    final DateTime fechaActual = (await NTP.now()).toUtc();

// Cálculo de la diferencia en días
    final Duration diferencia = fechaActual.difference(createdAtUtc);
    final int diasDesdeCreacion = diferencia.inDays;

    if (isAdmin && !isSubscribed && diasDesdeCreacion > 30) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('El periodo de prueba ha concluido'),
                content: const Text(
                  'Si quieres seguir usando las funcionalidades del programa debes suscribirte.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      context.push("/home/$taller");
                    },
                    child: const Text('Entiendo'),
                  ),
                  FilledButton(
                    onPressed: () {
                      context.push("/subscription");
                    },
                    child: const Text('Suscribirse'),
                  ),
                ],
              ),
            );
          },
        );
      });
    }
    return createdAtUtc;
  }
}
