// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assistify/main.dart';
import 'package:assistify/subscription/subscription_verifier.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/obtener_datos/obtener_total_info.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/supabase/utiles/actualizar_semanas.dart';
import 'package:assistify/supabase/utiles/feriados_false.dart';
import 'package:assistify/supabase/utiles/reset_clases.dart';
import 'package:assistify/utils/actualizar_fechas_database.dart';
import 'package:assistify/widgets/box_text.dart';
import 'package:assistify/widgets/contactanos.dart';
import 'package:assistify/widgets/information_buton.dart';
import 'package:assistify/widgets/responsive_appbar.dart';
import 'package:assistify/providers/auth_notifier.dart';
import 'package:assistify/providers/theme_provider.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/widgets/snackbar_animado.dart';

class Configuracion extends ConsumerStatefulWidget {
  const Configuracion({super.key, this.taller});

  final String? taller;

  @override
  _ConfiguracionState createState() => _ConfiguracionState();
}

class _ConfiguracionState extends ConsumerState<Configuracion> {
  User? user;
  String? taller;

  @override
  void initState() {
    super.initState();
    // Establece el usuario actual y el taller al inicializar
    user = ref.read(authProvider);
    _obtenerTallerUsuario();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
  }

  Future<void> _obtenerTallerUsuario() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final tallerObtenido =
        await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    setState(() {
      taller = tallerObtenido;
    });
  }

  Future<void> corregirDia() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(
            supabase: supabase, clasesTable: taller, usuariosTable: "usuarios")
        .obtenerClases();

    for (final clase in clases) {
      if (clase.dia == "miercoles") {
        await supabase
            .from(taller)
            .update({'dia': "miércoles"}).eq('id', clase.id);
      }
    }
  }

  Future<bool?> mostrarDialogoConfirmacionCambiarMes(
      BuildContext context, User user, ColorScheme color) async {
    int countdown = 5;
    bool isButtonEnabled = false;
    late StateSetter dialogSetState;
    late Timer countdownTimer;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            if (countdown == 5) {
              countdownTimer =
                  Timer.periodic(const Duration(seconds: 1), (timer) {
                if (countdown == 1) {
                  timer.cancel();
                  dialogSetState(() => isButtonEnabled = true);
                } else {
                  dialogSetState(() => countdown--);
                }
              });
            }

            return WillPopScope(
              onWillPop: () async {
                countdownTimer.cancel();
                return true;
              },
              child: AlertDialog(
                title: Text(user.userMetadata?["sexo"] == "Hombre"
                    ? "¿Estás seguro?"
                    : "¿Estás segura?"),
                content: const Text(
                  "Esta acción cerrará el mes actual y eliminará todas las clases anteriores. "
                  "Los créditos pendientes de los alumnos se mantienen. "
                  "Usá esta opción solo cuando quieras comenzar un nuevo mes desde cero.",
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () {
                      countdownTimer.cancel();
                      Navigator.of(context).pop(false);
                    },
                  ),
                  FilledButton(
                    onPressed: isButtonEnabled
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isButtonEnabled ? color.primary : Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFBCAAA4),
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text(
                        "Confirmar${isButtonEnabled ? '' : ' ($countdown)'}"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> mostrarDialogoConfirmacionEliminarCuenta(
      BuildContext context, User user, ColorScheme color) async {
    int countdown = 5;
    bool isButtonEnabled = false;
    late StateSetter dialogSetState;
    late Timer countdownTimer;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            // Iniciar cuenta regresiva solo una vez
            if (countdown == 5) {
              countdownTimer =
                  Timer.periodic(const Duration(seconds: 1), (timer) {
                if (countdown == 1) {
                  timer.cancel();
                  dialogSetState(() {
                    isButtonEnabled = true;
                  });
                } else {
                  dialogSetState(() {
                    countdown--;
                  });
                }
              });
            }

            return WillPopScope(
              onWillPop: () async {
                countdownTimer.cancel();
                return true;
              },
              child: AlertDialog(
                title: Text(user.userMetadata?["sexo"] == "Hombre"
                    ? "¿Estás seguro?"
                    : "¿Estás segura?"),
                content: const Text(
                  "⚠️ Si eliminás tu cuenta no vas a poder volver a acceder. "
                  "Tu administrador tendrá que crearte una nueva cuenta si querés volver a usar la app.",
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () {
                      countdownTimer.cancel();
                      Navigator.of(context).pop(false);
                    },
                  ),
                  FilledButton(
                    onPressed: isButtonEnabled
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isButtonEnabled ? color.primary : Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFBCAAA4),
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text(
                        "Eliminar${isButtonEnabled ? '' : ' ($countdown)'}"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> eliminarCuentaYUsuario({
    required BuildContext context,
    required String serviceRoleKey,
    required String supabaseUrl,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$supabaseUrl/auth/v1/admin/users/$userId'),
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
        },
      );

      if (response.statusCode == 204) {
        print("✅ Usuario eliminado del sistema de autenticación");

        // 2. Eliminar la fila asociada de la tabla 'usuarios'
        await supabase.from('usuarios').delete().eq('user_uid', userId);

        print("✅ Fila eliminada de la tabla 'usuarios'");
      } else {
        throw Exception('Error al eliminar cuenta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      if (context.mounted) {
        mostrarSnackBarAnimado(
          context: context,
          mensaje: "Ocurrió un error al eliminar la cuenta.",
          colorFondo: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final bool isDark = ref.watch(themeNotifyProvider).isDarkMode;
    final List<Color> colors = ref.watch(listTheColors);
    final int selectedColor = ref.watch(themeNotifyProvider).selectedColor;
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final List<Map<String, String>> options = [
      {
        'title': AppLocalizations.of(context).translate('changePassword'),
        'route': '/cambiarpassword',
      },
      if (taller != null)
        {
          'title': AppLocalizations.of(context).translate('changeUsername'),
          'route': '/cambiarfullname/$taller', // Ruta dinámica
        },
    ];

    return Scaffold(
        appBar: ResponsiveAppBar(isTablet: size.width > 600),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: user == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 80, color: Colors.grey),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('loginRequired'),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 150),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(
                            bottom: 100), // espacio para Contactanos
                        children: [
                          const SizedBox(height: 30),
                         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Card(
  color: color.surfaceVariant.withOpacity(0.6),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text(
      AppLocalizations.of(context).translate('chooseColor'),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color.primary,
      ),
    ),
  ),
),

          const SizedBox(height: 12),
          Wrap(
  spacing: 12,
  runSpacing: 12,
  children: List.generate(colors.length, (index) {
    final colorItem = colors[index];
    return GestureDetector(
      onTap: () => ref.read(themeNotifyProvider.notifier).changeColor(index),
      child: Container(
        decoration: BoxDecoration(
          color: colorItem,
          borderRadius: BorderRadius.circular(12),
          border: selectedColor == index
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        width: 50,
        height: 50,
        child:  null,
      ),
    );
  }),
),

          const Divider(),
          ListTile(
            title: Text(
              isDark
                  ? AppLocalizations.of(context).translate('lightMode')
                  : AppLocalizations.of(context).translate('darkMode'),
            ),
            leading: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onTap: () {
              ref.read(themeNotifyProvider.notifier).toggleDarkMode();
            },
          ),
        ],
      ),
    ),
  ),
),

                          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Card(
  color: color.surfaceVariant.withOpacity(0.6),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text(
      AppLocalizations.of(context).translate('updateData'),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).textTheme.titleMedium!.color!.withOpacity(0.9),
      ),
    ),
  ),
),

          const SizedBox(height: 12),
          ...options.map((option) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                title: Text(option['title']!),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push(option['route']!),
              ),
            );
          }).toList(),
        ],
      ),
    ),
  ),
),


                          // Botón para cambiar fechas
                          SizedBox(
                            height: 60,
                          ),
                          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Card(
    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título visual
          Card(
            color: color.surfaceVariant.withOpacity(0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                "Configuraciones avanzadas",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (user.userMetadata?["admin"] == true)
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text(
                  "Cambiar fechas al mes siguiente",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirmed =
                      await mostrarDialogoConfirmacionCambiarMes(
                          context, user, color);
                  if (confirmed == true) {
                    await corregirDia();
                    await ResetClases().reset();
                    await ActualizarFechasDatabase()
                        .actualizarClasesAlNuevoMes(
                            user.userMetadata?['taller'], 2025);
                    await ActualizarSemanas().actualizarSemana();
                    await FeriadosFalse().feriadosFalse();
                  }
                },
              ),
            ),

          const SizedBox(height: 12),

          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[300]!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text(
                "Eliminar mi cuenta",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final confirmed =
                    await mostrarDialogoConfirmacionEliminarCuenta(
                        context, user, color);
                if (confirmed == true) {
                  await EliminarUsuario().eliminarUsuarioAutenticado(user.id);
                  await EliminarUsuario().eliminarDeBaseDatos(user.id);
                  if (context.mounted) {
                    context.go("/");
                  }
                }
              },
            ),
          ),
        ],
      ),
    ),
  ),
),


                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),

            // Botón de información
            Positioned(
              bottom: 90,
              right: 20,
              child: InformationButon(text: '''
1️⃣ Desde esta pantalla podés personalizar los colores de la app.
Elegí el color de tema que más te guste para tu experiencia.

2️⃣ También podés activar o desactivar el modo oscuro.
Cambiá entre modo claro y modo oscuro según prefieras.

3️⃣ Además podés actualizar tus datos personales.
Podés cambiar tu contraseña o modificar tu nombre de usuario.

4️⃣ Usá el botón "Contactanos" para recibir ayuda.
Al presionar se despliegan tres opciones:

📞 Acceso directo a WhatsApp para chatear con el soporte de Assistify.

📧 Enviar un mensaje por mail a soporte, que será respondido en tu correo.

🤖 Iniciar un chat con un chatbot inteligente para obtener asistencia más rápida.
'''),
            ),
          ],
        ),
        floatingActionButton: Contactanos());
  }
}
