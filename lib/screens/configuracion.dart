// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:assistify/models/usuario_models.dart';
import 'package:assistify/supabase/obtener_datos/obtener_numero_admin.dart';
import 'package:assistify/utils/capitalize.dart';
import 'package:assistify/widgets/titulo_seleccion.dart';
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
  late Future<List<UsuarioModels>> _usuariosFuture;

  @override
  void initState() {
    super.initState();
    user = ref.read(authProvider);
    _obtenerTallerUsuario();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
    _usuariosFuture = ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller ?? '',
    ).obtenerUsuarios();
  }

  Future<void> _obtenerTallerUsuario() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final tallerObtenido =
        await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    setState(() {
      taller = tallerObtenido;
      _usuariosFuture = ObtenerTotalInfo(
        supabase: supabase,
        usuariosTable: 'usuarios',
        clasesTable: tallerObtenido,
      ).obtenerUsuarios();
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
    final sexo = user?.userMetadata?['sexo'];
    final fullName = user?.userMetadata?['fullname'] ?? '';

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
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 40),
                                TituloSeleccion(
                                  texto: "Personalizar mi cuenta ",
                                ),
                                const SizedBox(height: 3),
                                const Divider(thickness: 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ExpandibleCard(
                              titulo: AppLocalizations.of(context)
                                  .translate('chooseColor'),
                              contenido: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children:
                                        List.generate(colors.length, (index) {
                                      final colorItem = colors[index];
                                      return GestureDetector(
                                        onTap: () => ref
                                            .read(themeNotifyProvider.notifier)
                                            .changeColor(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: colorItem,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: selectedColor == index
                                                ? Border.all(
                                                    color: Colors.white,
                                                    width: 3)
                                                : null,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          width: 50,
                                          height: 50,
                                        ),
                                      );
                                    }),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    title: Text(
                                      isDark
                                          ? AppLocalizations.of(context)
                                              .translate('lightMode')
                                          : AppLocalizations.of(context)
                                              .translate('darkMode'),
                                    ),
                                    leading: Icon(
                                      isDark
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
                                    ),
                                    onTap: () {
                                      ref
                                          .read(themeNotifyProvider.notifier)
                                          .toggleDarkMode();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ExpandibleCard(
                              titulo: AppLocalizations.of(context)
                                  .translate('updateData'),
                              contenido: StatefulBuilder(
                                builder: (context, setState) {
                                  final sexo = user?.userMetadata?['sexo'];
                                  final fullName =
                                      user?.userMetadata?['fullname'] ?? '';
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Nombre
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text('Nombre: $fullName'),
                                          onTap: () async {
                                            final controller =
                                                TextEditingController(
                                                    text: fullName);
                                            String? errorMessage;
                                            bool isLoading = false;

                                            await showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Actualizar nombre'),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextField(
                                                            controller:
                                                                controller,
                                                            decoration:
                                                                const InputDecoration(
                                                                    labelText:
                                                                        'Nuevo nombre'),
                                                          ),
                                                          if (errorMessage !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8),
                                                              child: Text(
                                                                  errorMessage!,
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .red)),
                                                            ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Cancelar'),
                                                        ),
                                                        TextButton(
                                                          onPressed: isLoading
                                                              ? null
                                                              : () async {
                                                                  final nuevoNombre =
                                                                      controller
                                                                          .text
                                                                          .trim();
                                                                  if (nuevoNombre
                                                                      .isEmpty) {
                                                                    setState(
                                                                        () {
                                                                      errorMessage =
                                                                          'El nombre no puede estar vacío';
                                                                    });
                                                                    return;
                                                                  }

                                                                  setState(() {
                                                                    isLoading =
                                                                        true;
                                                                    errorMessage =
                                                                        null;
                                                                  });

                                                                  final listausuarios =
                                                                      await ObtenerTotalInfo(
                                                                    supabase:
                                                                        supabase,
                                                                    usuariosTable:
                                                                        'usuarios',
                                                                    clasesTable:
                                                                        taller!,
                                                                  ).obtenerUsuarios();

                                                                  final fullnameExiste = listausuarios.any((usuario) =>
                                                                      usuario
                                                                          .fullname
                                                                          .toLowerCase() ==
                                                                      nuevoNombre
                                                                          .toLowerCase());

                                                                  if (fullnameExiste) {
                                                                    setState(
                                                                        () {
                                                                      errorMessage =
                                                                          'Ese nombre ya está registrado. Elegí otro.';
                                                                      isLoading =
                                                                          false;
                                                                    });
                                                                    return;
                                                                  }

                                                                  try {
                                                                    final user = Supabase
                                                                        .instance
                                                                        .client
                                                                        .auth
                                                                        .currentUser;

                                                                    await Supabase
                                                                        .instance
                                                                        .client
                                                                        .auth
                                                                        .updateUser(
                                                                      UserAttributes(
                                                                          data: {
                                                                            'fullname':
                                                                                Capitalize().capitalize(nuevoNombre)
                                                                          }),
                                                                    );

                                                                    await UpdateUser(supabase).updateUser(
                                                                        fullName,
                                                                        Capitalize()
                                                                            .capitalize(nuevoNombre));

                                                                    await UpdateUser(supabase).updateTableUser(
                                                                        user!
                                                                            .id,
                                                                        Capitalize()
                                                                            .capitalize(nuevoNombre));

                                                                    if (context
                                                                        .mounted) {
                                                                      Navigator.pop(
                                                                          context);
                                                                      mostrarSnackBarAnimado(
                                                                        context:
                                                                            context,
                                                                        mensaje:
                                                                            'Nombre actualizado correctamente',
                                                                        colorFondo:
                                                                            Colors.lightGreen,
                                                                      );
                                                                    }
                                                                  } finally {
                                                                    setState(
                                                                        () {
                                                                      isLoading =
                                                                          false;
                                                                    });
                                                                  }
                                                                },
                                                          child: isLoading
                                                              ? const CircularProgressIndicator()
                                                              : const Text(
                                                                  'Confirmar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      // Sexo
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text(
                                              'Sexo: ${sexo ?? "Sin especificar"}'),
                                          onTap: () async {
                                            String? sexoSeleccionado =
                                                sexo ?? 'Otro';
                                            await showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Seleccionar sexo'),
                                                  content: StatefulBuilder(
                                                    builder:
                                                        (context, setState) {
                                                      return Row(
                                                        children: [
                                                          'Hombre',
                                                          'Mujer',
                                                          'Otro'
                                                        ]
                                                            .asMap()
                                                            .entries
                                                            .map((entry) {
                                                          final index =
                                                              entry.key;
                                                          final opcion =
                                                              entry.value;
                                                          final esSeleccionado =
                                                              sexoSeleccionado ==
                                                                  opcion;

                                                          return Expanded(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  sexoSeleccionado =
                                                                      opcion;
                                                                });
                                                              },
                                                              child: Container(
                                                                margin: EdgeInsets.only(
                                                                    left: index >
                                                                            0
                                                                        ? 8
                                                                        : 0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: esSeleccionado
                                                                      ? color
                                                                          .primary
                                                                          .withOpacity(
                                                                              0.1)
                                                                      : const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          229,
                                                                          233,
                                                                          239),
                                                                  border: Border
                                                                      .all(
                                                                    color: esSeleccionado
                                                                        ? color
                                                                            .primary
                                                                        : const Color
                                                                            .fromARGB(
                                                                            255,
                                                                            119,
                                                                            119,
                                                                            120),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        10,
                                                                    horizontal:
                                                                        6),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      esSeleccionado
                                                                          ? Icons
                                                                              .radio_button_checked
                                                                          : Icons
                                                                              .radio_button_off,
                                                                      size: 18,
                                                                      color: color
                                                                          .primary,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            6),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        opcion,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight: esSeleccionado
                                                                              ? FontWeight.bold
                                                                              : FontWeight.normal,
                                                                          color: esSeleccionado
                                                                              ? color.primary
                                                                              : Colors.black87,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      );
                                                    },
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text(
                                                          'Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        final valorAGuardar =
                                                            sexoSeleccionado ==
                                                                    "Otro"
                                                                ? "Indefinido"
                                                                : sexoSeleccionado;
                                                        await Supabase.instance
                                                            .client.auth
                                                            .updateUser(
                                                          UserAttributes(data: {
                                                            'sexo':
                                                                valorAGuardar
                                                          }),
                                                        );
                                                        await Supabase
                                                            .instance.client
                                                            .from('usuarios')
                                                            .update({
                                                          'sexo': sexoSeleccionado ==
                                                                  'Otro'
                                                              ? 'Indefinido'
                                                              : sexoSeleccionado
                                                        }).eq('user_uid',
                                                                user.id);

                                                        if (context.mounted) {
                                                          Navigator.pop(
                                                              context);
                                                          mostrarSnackBarAnimado(
                                                            context: context,
                                                            mensaje:
                                                                'Sexo actualizado correctamente',
                                                            colorFondo: Colors
                                                                .lightGreen,
                                                          );
                                                        }
                                                      },
                                                      child:
                                                          const Text('Guardar'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      // Teléfono
                                      FutureBuilder<String?>(
                                        future: ObtenerNumero()
                                            .obtenerTelefonoPorNombre(fullName),
                                        builder: (context, snapshot) {
                                          final telefono =
                                              snapshot.data ?? 'Sin registrar';
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            elevation: 2,
                                            child: ListTile(
                                              title:
                                                  Text('Teléfono: $telefono'),
                                              onTap: () async {
                                                final controller =
                                                    TextEditingController(
                                                        text: telefono);
                                                await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Actualizar teléfono'),
                                                      content: TextField(
                                                        controller: controller,
                                                        keyboardType:
                                                            TextInputType.phone,
                                                        decoration:
                                                            const InputDecoration(
                                                          labelText:
                                                              'Nuevo número',
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Cancelar'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Supabase.instance
                                                                .client.auth
                                                                .updateUser(
                                                              UserAttributes(
                                                                  data: {
                                                                    'telefono':
                                                                        controller
                                                                            .text
                                                                  }),
                                                            );
                                                            await Supabase
                                                                .instance.client
                                                                .from(
                                                                    'usuarios')
                                                                .update({
                                                              'telefono':
                                                                  controller
                                                                      .text
                                                            }).eq('fullname',
                                                                    fullName);
                                                            if (context
                                                                .mounted) {
                                                              Navigator.pop(
                                                                  context);
                                                              mostrarSnackBarAnimado(
                                                                context:
                                                                    context,
                                                                mensaje:
                                                                    'Teléfono actualizado correctamente',
                                                                colorFondo: Colors
                                                                    .lightGreen,
                                                              );
                                                            }
                                                          },
                                                          child: const Text(
                                                              'Guardar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      // Contraseña
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 2,
                                        child: ListTile(
                                          title: const Text(
                                              'Contraseña: ********'),
                                          onTap: () async {
                                            final passwordController =
                                                TextEditingController();
                                            final confirmPasswordController =
                                                TextEditingController();
                                            String passwordError = '';
                                            String confirmPasswordError = '';

                                            await showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Cambiar contraseña'),
                                                      content:
                                                          SingleChildScrollView(
                                                        child: Column(
                                                          children: [
                                                            TextField(
                                                              controller:
                                                                  passwordController,
                                                              obscureText: true,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText:
                                                                    'Nueva contraseña',
                                                                errorText: passwordError
                                                                        .isEmpty
                                                                    ? null
                                                                    : passwordError,
                                                              ),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  passwordError =
                                                                      value.length <
                                                                              6
                                                                          ? 'La contraseña debe tener al menos 6 caracteres'
                                                                          : '';
                                                                });
                                                              },
                                                            ),
                                                            const SizedBox(
                                                                height: 16),
                                                            TextField(
                                                              controller:
                                                                  confirmPasswordController,
                                                              obscureText: true,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText:
                                                                    'Confirmar contraseña',
                                                                errorText: confirmPasswordError
                                                                        .isEmpty
                                                                    ? null
                                                                    : confirmPasswordError,
                                                              ),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  confirmPasswordError = value !=
                                                                          passwordController
                                                                              .text
                                                                      ? 'Las contraseñas no coinciden'
                                                                      : '';
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Cancelar'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            final nuevaPassword =
                                                                passwordController
                                                                    .text
                                                                    .trim();
                                                            final confirmarPassword =
                                                                confirmPasswordController
                                                                    .text
                                                                    .trim();

                                                            if (nuevaPassword
                                                                    .isEmpty ||
                                                                confirmarPassword
                                                                    .isEmpty) {
                                                              setState(() {
                                                                passwordError =
                                                                    'Todos los campos son obligatorios';
                                                              });
                                                              return;
                                                            }

                                                            if (nuevaPassword
                                                                    .length <
                                                                6) {
                                                              setState(() {
                                                                passwordError =
                                                                    'La contraseña debe tener al menos 6 caracteres';
                                                              });
                                                              return;
                                                            }

                                                            if (nuevaPassword !=
                                                                confirmarPassword) {
                                                              setState(() {
                                                                confirmPasswordError =
                                                                    'Las contraseñas no coinciden';
                                                              });
                                                              return;
                                                            }

                                                            try {
                                                              await Supabase
                                                                  .instance
                                                                  .client
                                                                  .auth
                                                                  .updateUser(
                                                                UserAttributes(
                                                                    password:
                                                                        nuevaPassword),
                                                              );

                                                              if (context
                                                                  .mounted) {
                                                                Navigator.pop(
                                                                    context);
                                                                mostrarSnackBarAnimado(
                                                                  context:
                                                                      context,
                                                                  mensaje: AppLocalizations.of(
                                                                          context)
                                                                      .translate(
                                                                          'passwordUpdatedSuccess'),
                                                                  colorFondo: Colors
                                                                      .lightGreen,
                                                                );
                                                              }
                                                            } catch (e) {
                                                              final error =
                                                                  e.toString();
                                                              if (error.contains(
                                                                  'same_password')) {
                                                                mostrarSnackBarAnimado(
                                                                  context:
                                                                      context,
                                                                  mensaje:
                                                                      'Debes ingresar una contraseña distinta a la actual.',
                                                                  colorFondo:
                                                                      Colors
                                                                          .red,
                                                                );
                                                              } else {
                                                                mostrarSnackBarAnimado(
                                                                  context:
                                                                      context,
                                                                  mensaje: AppLocalizations.of(
                                                                          context)
                                                                      .translate(
                                                                          'passwordUpdateError',
                                                                          params: {
                                                                        'error':
                                                                            error
                                                                      }),
                                                                  colorFondo:
                                                                      Colors
                                                                          .red,
                                                                );
                                                              }
                                                            }
                                                          },
                                                          child: const Text(
                                                              'Confirmar'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ExpandibleCard(
                              titulo: "Funciones sensibles",
                              contenido: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user.userMetadata?["admin"] == true)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red[700],
                                          side: BorderSide(
                                              color: Colors.red[300]!),
                                          padding: const EdgeInsets.only(
                                              right: 25,
                                              left: 10,
                                              top: 12,
                                              bottom: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.warning_amber_rounded),
                                        label: const Text(
                                          "Cambiar fechas al mes siguiente",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
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
                                                    user.userMetadata?[
                                                        'taller'],
                                                    2025);
                                            await ActualizarSemanas()
                                                .actualizarSemana();
                                            await FeriadosFalse()
                                                .feriadosFalse();
                                          }
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[700],
                                        side:
                                            BorderSide(color: Colors.red[300]!),
                                        padding: const EdgeInsets.only(
                                            right: 25,
                                            left: 10,
                                            top: 12,
                                            bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(
                                          Icons.delete_forever_rounded),
                                      label: const Text(
                                        "Eliminar mi cuenta",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () async {
                                        final confirmed =
                                            await mostrarDialogoConfirmacionEliminarCuenta(
                                                context, user, color);
                                        if (confirmed == true) {
                                          await EliminarUsuario()
                                              .eliminarUsuarioAutenticado(
                                                  user.id);
                                          await EliminarUsuario()
                                              .eliminarDeBaseDatos(user.id);
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
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
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

class ExpandibleCard extends StatefulWidget {
  final String titulo;
  final Widget contenido;
  final bool? expandInitially;

  const ExpandibleCard({
    super.key,
    required this.titulo,
    required this.contenido,
    this.expandInitially,
  });

  @override
  State<ExpandibleCard> createState() => _ExpandibleCardState();
}

class _ExpandibleCardState extends State<ExpandibleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  double? _fullWidth;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expandInitially ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: widget.titulo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      setState(() {
        _fullWidth = textPainter.size.width + 10;
      });
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: _expanded ? 1 : 0,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.titulo),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final width =
                        _fullWidth != null ? _fullWidth! * _animation.value : 0;
                    return SizedBox(
                      height: 1.1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: width.toDouble(),
                          child: const Divider(thickness: 1.1),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            trailing: RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.5).animate(_controller),
              child: const Icon(Icons.expand_more),
            ),
            onTap: toggle,
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints: _expanded
                    ? const BoxConstraints()
                    : const BoxConstraints(maxHeight: 0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.contenido,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
