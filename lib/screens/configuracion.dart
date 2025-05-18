// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  padding: const EdgeInsets.only(bottom: 100), // espacio para Contactanos
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
    const SizedBox(height: 20),
    user!.userMetadata?["admin"] == true ? 
    Center(
      child: Center(
  child: OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.red[700], // color del texto e ícono
      side: BorderSide(color: Colors.red[300]!), // borde
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
      final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) {
    int countdown = 5;
    bool isButtonEnabled = false;
    late StateSetter dialogSetState;
    late Timer countdownTimer;

    return StatefulBuilder(
      builder: (context, setState) {
        dialogSetState = setState;

        // Iniciar el timer solo una vez
        if (countdown == 5) {
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (countdown == 1) {
              timer.cancel();
              if (mounted) {
                dialogSetState(() {
                  isButtonEnabled = true;
                });
              }
            } else {
              if (mounted) {
                dialogSetState(() {
                  countdown--;
                });
              }
            }
          });
        }

        return WillPopScope(
          onWillPop: () async {
            countdownTimer.cancel();
            return true;
          },
          child: AlertDialog(
            title: Text( user.userMetadata?['sexo'] == "Hombre"  ?  "¿Estás seguro?" : "¿Estás segura?" ),
            content: const Text(
              "Esta acción cerrará el mes actual y eliminará todas las clases del mes anterior, dejando los horarios vacíos y listos para reasignar alumnos. \n\nLos creditos que los alumnos tengan disponibles para recuperar una clase se mantienen",
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
                    ?  () async {
        countdownTimer.cancel();
Navigator.of(context).pop();

await corregirDia(); // ← 1: Corregí días mal escritos
await ResetClases().reset(); // ← 2: Vaciar mails y espera
await ActualizarFechasDatabase()
    .actualizarClasesAlNuevoMes(user.userMetadata?['taller'], 2025); // ← 3: Actualizar fechas (ya con clases vacías)

await ActualizarSemanas().actualizarSemana(); // ← 4: Asignar semana y resetear lugares
await FeriadosFalse().feriadosFalse(); // ← 5: Marcar todos como no feriado

      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? color.primary
                      : Colors.red, // gris con borde bordó
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


    },
  ),
),

    ):
    const SizedBox(),

    const SizedBox(height: 20),
  ],
),

              ),
            ),
            Positioned(
              bottom: 90, // espacio para no tapar el botón de Contactanos
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
