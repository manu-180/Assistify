  // ignore_for_file: library_private_types_in_public_api

  import 'dart:async';

  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:taller_ceramica/main.dart';
  import 'package:taller_ceramica/subscription/subscription_verifier.dart';
  import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
  import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
  import 'package:taller_ceramica/supabase/utiles/actualizar_semanas.dart';
  import 'package:taller_ceramica/supabase/utiles/feriados_false.dart';
  import 'package:taller_ceramica/supabase/utiles/reset_clases.dart';
  import 'package:taller_ceramica/utils/actualizar_fechas_database.dart';
  import 'package:taller_ceramica/widgets/box_text.dart';
  import 'package:taller_ceramica/widgets/contactanos.dart';
  import 'package:taller_ceramica/widgets/information_buton.dart';
  import 'package:taller_ceramica/widgets/responsive_appbar.dart';
  import 'package:taller_ceramica/providers/auth_notifier.dart';
  import 'package:taller_ceramica/providers/theme_provider.dart';
  import 'package:taller_ceramica/l10n/app_localizations.dart';

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
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
                    backgroundColor: isButtonEnabled ? color.primary : Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBCAAA4),
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: Text("Confirmar${isButtonEnabled ? '' : ' ($countdown)'}"),
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
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
                  child: Text("Eliminar${isButtonEnabled ? '' : ' ($countdown)'}"),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Ocurrió un error al eliminar la cuenta."),
        backgroundColor: Colors.red,
      ));
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
                    const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context).translate('loginRequired'),
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
                          ExpansionTile(
                            title: Text(
                              AppLocalizations.of(context)
                                  .translate('chooseColor'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: colors.length,
                                itemBuilder: (context, index) {
                                  final color = colors[index];
                                  return RadioListTile(
                                    title: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.palette_outlined,
                                            color: color, size: 35),
                                        const SizedBox(width: 15),
                                        Icon(Icons.palette_outlined,
                                            color: color, size: 35),
                                        const SizedBox(width: 15),
                                        Icon(Icons.palette_outlined,
                                            color: color, size: 35),
                                        const SizedBox(width: 15),
                                      ],
                                    ),
                                    activeColor: color,
                                    value: index,
                                    groupValue: selectedColor,
                                    onChanged: (value) {
                                      ref
                                          .read(themeNotifyProvider.notifier)
                                          .changeColor(index);
                                    },
                                  );
                                },
                              ),
                              ListTile(
                                title: Text(
                                  isDark
                                      ? AppLocalizations.of(context)
                                          .translate('lightMode')
                                      : AppLocalizations.of(context)
                                          .translate('darkMode'),
                                ),
                                onTap: () {
                                  ref
                                      .read(themeNotifyProvider.notifier)
                                      .toggleDarkMode();
                                },
                                leading: isDark
                                    ? const Icon(Icons.light_mode_outlined)
                                    : const Icon(Icons.dark_mode_outlined),
                              ),
                            ],
                          ), // Elige color
                          ExpansionTile(
                            title: Text(
                              AppLocalizations.of(context)
                                  .translate('updateData'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options[index];
                                  return ListTile(
                                    title: Text(option['title']!),
                                    onTap: () => context.push(option['route']!),
                                  );
                                },
                              ),
                            ],
                          ), // Actualizar datos

                  // Botón para cambiar fechas
                  SizedBox(height: 60,),
                  if (user.userMetadata?["admin"] == true)
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[300]!),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          final confirmed = await mostrarDialogoConfirmacionCambiarMes(context, user, color);
                          if (confirmed == true) {
                            await corregirDia();
                            await ResetClases().reset();
                            await ActualizarFechasDatabase().actualizarClasesAlNuevoMes(user.userMetadata?['taller'], 2025);
                            await ActualizarSemanas().actualizarSemana();
                            await FeriadosFalse().feriadosFalse();
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Botón para eliminar cuenta
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text(
                        "Eliminar mi cuenta",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
  final confirmed = await mostrarDialogoConfirmacionEliminarCuenta(context, user, color);
  if (confirmed == true) {
    await eliminarCuentaYUsuario(
      context: context,
      userId: user.id,
      supabaseUrl: 'https://gcjyhrlcftbkeaiqlzlm.supabase.co',
      serviceRoleKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjanlocmxjZnRia2VhaXFsemxtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxNTcyNDc3MCwiZXhwIjoyMDMxMzAwNzcwfQ.HC-tuFM2oMqJt2jjbuRHJ3fdLbXIMnn4OtBGBPcufwA',
    );
  }
},

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
