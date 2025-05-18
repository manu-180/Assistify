import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/subscription/subscription_verifier.dart';
import 'package:taller_ceramica/supabase/clases/agregar_usuario.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_feriado.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_feriado.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_mes.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/supabase/clases/remover_usuario.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/utils/actualizar_fechas_database.dart';
import 'package:taller_ceramica/utils/enviar_wpp.dart';
import 'package:taller_ceramica/widgets/box_text.dart';
import 'package:taller_ceramica/utils/generar_fechas_del_mes.dart';
import 'package:taller_ceramica/widgets/information_buton.dart';
import 'package:taller_ceramica/widgets/mostrar_dia_segun_fecha.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';

import 'package:taller_ceramica/utils/dia_con_fecha.dart';

class GestionHorariosScreen extends StatefulWidget {
  const GestionHorariosScreen({super.key, String? taller});

  @override
  State<GestionHorariosScreen> createState() => _GestionHorariosScreenState();
}

class _GestionHorariosScreenState extends State<GestionHorariosScreen> {
  List<String> fechasDisponibles = [];
  String? fechaSeleccionada;
  List<ClaseModels> horariosDisponibles = [];
  List<ClaseModels> horariosFiltrados = [];
  bool isLoading = true;

  // Para la parte de usuarios
  List<String> usuariosDisponibles = [];
  String usuarioSeleccionado = "";
  TextEditingController usuarioController = TextEditingController();
  List<String> usuariosDisponiblesOriginal = [];
  bool insertarX4 = false;
  late BuildContext scaffoldContext;

  final actualizarFechasDatabase = ActualizarFechasDatabase();

  @override
  void initState() {
    super.initState();
    inicializarDatos();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
  }

  Future<void> inicializarDatos() async {
    try {
      final mes = await ObtenerMes().obtenerMes();
      setState(() {
        fechasDisponibles =
            GenerarFechasDelMes().generarFechasDelMes(mes, 2025);
      });

      await cargarDatos();
    } catch (e) {
      debugPrint('Error al inicializar los datos: $e');
    }
  }

  Future<void> cargarDatos() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    try {
      final datos = await ObtenerTotalInfo(
        supabase: supabase,
        usuariosTable: 'usuarios',
        clasesTable: taller,
      ).obtenerClases();

      final usuarios = await ObtenerTotalInfo(
        supabase: supabase,
        usuariosTable: 'usuarios',
        clasesTable: taller,
      ).obtenerUsuarios();

      final datosDiciembre = datos.where((clase) {
        final fecha = clase.fecha;
        return fecha.endsWith('/2025');
      }).toList();

      final usuariosFiltrados = usuarios.where((usuario) {
        return usuario.taller == taller;
      }).toList();

      final nombresFiltrados =
          usuariosFiltrados.map((usuario) => usuario.fullname).toList();

      setState(() {
        horariosDisponibles = datosDiciembre.cast<ClaseModels>();
        horariosFiltrados = datosDiciembre.cast<ClaseModels>();

        usuariosDisponibles = nombresFiltrados.cast<String>();
        usuariosDisponiblesOriginal = List.from(nombresFiltrados);

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error cargando datos: $e');
    }
  }

  void seleccionarFecha(String fecha) {
    setState(() {
      fechaSeleccionada = fecha;
      horariosFiltrados = horariosDisponibles
          .where((clase) => clase.fecha == fechaSeleccionada)
          .toList();

      horariosFiltrados.sort((a, b) {
        final formatoFecha = DateFormat('dd/MM/yyyy');
        final fechaA = formatoFecha.parse(a.fecha);
        final fechaB = formatoFecha.parse(b.fecha);

        if (fechaA == fechaB) {
          final formatoHora = DateFormat('HH:mm');
          final horaA = formatoHora.parse(a.hora);
          final horaB = formatoHora.parse(b.hora);
          return horaA.compareTo(horaB);
        }
        return fechaA.compareTo(fechaB);
      });
    });
  }

  void cambiarFecha(bool siguiente) {
    setState(() {
      if (fechaSeleccionada != null) {
        final int indexActual = fechasDisponibles.indexOf(fechaSeleccionada!);

        if (siguiente) {
          fechaSeleccionada =
              fechasDisponibles[(indexActual + 1) % fechasDisponibles.length];
        } else {
          fechaSeleccionada = fechasDisponibles[
              (indexActual - 1 + fechasDisponibles.length) %
                  fechasDisponibles.length];
        }
        seleccionarFecha(fechaSeleccionada!);
      } else {
        if (fechasDisponibles.isNotEmpty) {
          fechaSeleccionada = fechasDisponibles[0];
          seleccionarFecha(fechaSeleccionada!);
        } else {
          print("⚠️ No hay fechas disponibles");
        }
      }
    });
  }

  String _obtenerDia(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '';
    return DiaConFecha()
        .obtenerDiaDeLaSemana(fecha, AppLocalizations.of(context));
  }

  void mostrarSnackBarConDetalle({
    required BuildContext context,
    required String titulo,
    required List<ClaseModels> clases,
    required Color colorFondo,
  }) {
    final detalles =
        clases.map((cl) => '${cl.dia} ${cl.fecha} a las ${cl.hora}').join('\n');
    final mensaje = '$titulo:\n\n$detalles';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 7),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          child: SlideInUp(
            duration: const Duration(milliseconds: 500),
            child: Material(
              // 👈 clave para que el tap funcione bien
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> mostrarDialogo(String tipoAccion, ClaseModels clase,
      ColorScheme color, BuildContext scaffoldContext) async {
    final localizations = AppLocalizations.of(context);
    final usuarioActivo = Supabase.instance.client.auth.currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> usuariosFiltrados = List.from(usuariosDisponibles);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(localizations.translate(tipoAccion == "insertar"
                  ? 'selectUserToAdd'
                  : 'selectUserToRemove')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usuarioController,
                      decoration: InputDecoration(
                        hintText: localizations.translate('searchUserHint'),
                      ),
                      onChanged: (texto) {
                        setStateDialog(() {
                          usuariosFiltrados = usuariosDisponibles
                              .where((usuario) => usuario
                                  .toLowerCase()
                                  .contains(texto.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    usuariosFiltrados.isNotEmpty
                        ? Flexible(
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: usuariosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final usuario = usuariosFiltrados[index];
                                  return ListTile(
                                    title: Text(usuario),
                                    onTap: () {
                                      setStateDialog(() {
                                        usuarioSeleccionado = usuario;
                                      });
                                    },
                                    selected: usuarioSeleccionado == usuario,
                                  );
                                },
                              ),
                            ),
                          )
                        : Center(
                            child:
                                Text(localizations.translate('noUsersFound')),
                          ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(localizations.translate(tipoAccion == "insertar"
                            ? 'insertX4'
                            : 'removeX4')),
                        Switch(
                          value: insertarX4,
                          onChanged: (value) {
                            setStateDialog(() {
                              insertarX4 = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancelar a la izquierda
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(localizations.translate('cancelButton')),
                        ),
                        // Agregar o Remover a la derecha
                        ElevatedButton(
                          onPressed: () async {
                            if (usuarioSeleccionado.isEmpty) return;

                            Navigator.of(context).pop();

                            final ScaffoldMessengerState? messenger =
                                ScaffoldMessenger.of(scaffoldContext);

                            if (tipoAccion == "insertar") {
                              if (insertarX4) {
                                await AgregarUsuario(supabase)
                                    .agregarUsuarioEnCuatroClases(
                                  context,
                                  clase,
                                  usuarioSeleccionado,
                                  (ClaseModels claseActualizada) {
                                    // callback para actualizar clases localmente
                                    if (mounted) {
                                      setState(() {
                                        final idx = horariosDisponibles
                                            .indexWhere((c) =>
                                                c.id == claseActualizada.id);
                                        if (idx != -1)
                                          horariosDisponibles[idx] =
                                              claseActualizada;

                                        final idxFiltrado =
                                            horariosFiltrados.indexWhere((c) =>
                                                c.id == claseActualizada.id);
                                        if (idxFiltrado != -1)
                                          horariosFiltrados[idxFiltrado] =
                                              claseActualizada;
                                      });
                                    }
                                  },
                                  (int total,
                                      List<ClaseModels> clasesAfectadas) {
                                    if (!mounted) return;
                                    // callback para mostrar el snackbar
                                    final detalles = clasesAfectadas
                                        .map((cl) =>
                                            "${cl.dia} ${cl.fecha} a las ${cl.hora}")
                                        .join("\n");
                                    final mensaje =
                                        'Se agregó a $usuarioSeleccionado en ${clasesAfectadas.length} clases:\n\n$detalles';

                                    ScaffoldMessenger.of(scaffoldContext)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(scaffoldContext)
                                        .showSnackBar(
                                      SnackBar(
                                        duration: const Duration(seconds: 7),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        content: GestureDetector(
                                          onTap: () => ScaffoldMessenger.of(
                                                  scaffoldContext)
                                              .hideCurrentSnackBar(),
                                          child: SlideInUp(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: color.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  mensaje,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );

                                print(
                                    "SE LE MANDA MENSAJE AL NUMERO : ${usuarioActivo!.userMetadata?["telefono"]}");
                                EnviarWpp().sendWhatsAppMessage(
                                    "HX6dad986ed219654d62aed35763d10ccb",
                                    'whatsapp:+549${usuarioActivo.userMetadata?["telefono"]}',
                                    [
                                      usuarioSeleccionado,
                                      clase.dia,
                                      clase.fecha,
                                      clase.hora,
                                      ""
                                    ]);
                              } else {
                                await AgregarUsuario(supabase)
                                    .agregarUsuarioAClase(
                                  clase.id,
                                  usuarioSeleccionado,
                                  true,
                                  clase,
                                );
                                print(
                                    "SE LE MANDA MENSAJE AL NUMERO : ${usuarioActivo!.userMetadata?["telefono"]}");

                                EnviarWpp().sendWhatsAppMessage(
                                    "HX13d84cd6816c60f21f172fe42bb3b0bb",
                                    'whatsapp:+549${usuarioActivo.userMetadata?["telefono"]}',
                                    [
                                      usuarioSeleccionado,
                                      clase.dia,
                                      clase.fecha,
                                      clase.hora,
                                      ""
                                    ]);

                                if (mounted) {
                                  setState(() {
                                    clase.mails.add(usuarioSeleccionado);
                                    mostrarSnackBarConDetalle(
                                      context: scaffoldContext,
                                      titulo:
                                          'Se agregó a $usuarioSeleccionado en la clase',
                                      clases: [clase],
                                      colorFondo: color.primary,
                                    );
                                  });
                                }
                              }
                            } else if (tipoAccion == "remover") {
                              if (insertarX4) {
                                await RemoverUsuario(supabase)
                                    .removerUsuarioDeMuchasClase(
                                  clase,
                                  usuarioSeleccionado,
                                  (ClaseModels claseActualizada) {
                                    if (mounted) {
                                      setState(() {
                                        final idx = horariosDisponibles
                                            .indexWhere((c) =>
                                                c.id == claseActualizada.id);
                                        if (idx != -1)
                                          horariosDisponibles[idx] =
                                              claseActualizada;

                                        final idxFiltrado =
                                            horariosFiltrados.indexWhere((c) =>
                                                c.id == claseActualizada.id);
                                        if (idxFiltrado != -1)
                                          horariosFiltrados[idxFiltrado] =
                                              claseActualizada;
                                      });
                                    }
                                  },
                                  (List<ClaseModels> clasesAfectadas) {
                                    if (!mounted) return;

                                    mostrarSnackBarConDetalle(
                                      context: scaffoldContext,
                                      titulo:
                                          'Se removió a $usuarioSeleccionado de ${clasesAfectadas.length} clases',
                                      clases: clasesAfectadas,
                                      colorFondo: color.primary,
                                    );
                                  },
                                );
                                print(
                                    "SE LE MANDA MENSAJE AL NUMERO : ${usuarioActivo!.userMetadata?["telefono"]}");

                                EnviarWpp().sendWhatsAppMessage(
                                  "HX5a0f97cd3b0363325e3b1cc6c4d6a372",
                                  'whatsapp:+549${usuarioActivo.userMetadata?["telefono"]}',
                                  [usuarioSeleccionado, clase.dia, "", "", ""],
                                );
                              } else {
                                await RemoverUsuario(supabase)
                                    .removerUsuarioDeClase(
                                  clase.id,
                                  usuarioSeleccionado,
                                  true,
                                );
                                print(
                                    "SE LE MANDA MENSAJE AL NUMERO : ${usuarioActivo!.userMetadata?["telefono"]}");

                                EnviarWpp().sendWhatsAppMessage(
                                    "HXc0f22718dded5d710b659d89b4117bb1",
                                    'whatsapp:+549${usuarioActivo.userMetadata?["telefono"]}',
                                    [
                                      usuarioSeleccionado,
                                      clase.dia,
                                      clase.fecha,
                                      clase.hora,
                                      ""
                                    ]);

                                if (mounted) {
                                  setState(() {
                                    clase.mails.remove(usuarioSeleccionado);
                                    mostrarSnackBarConDetalle(
                                      context: scaffoldContext,
                                      titulo:
                                          'Se removió a $usuarioSeleccionado de la clase',
                                      clases: [clase],
                                      colorFondo: color.primary,
                                    );
                                  });
                                }
                              }
                            }
                          },
                          child: Text(localizations.translate(
                              tipoAccion == "insertar"
                                  ? 'addButton'
                                  : 'removeButton')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = Theme.of(context).primaryColor;
    final colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    final partesFecha = fechaSeleccionada?.split('/');
    final diaMes = '${partesFecha?[0]}/${partesFecha?[1]}';

    return Builder(builder: (BuildContext context) {
      scaffoldContext = context;
      return Scaffold(
        appBar: ResponsiveAppBar(isTablet: size.width > 600),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  MostrarDiaSegunFecha(
                    text: fechaSeleccionada ?? '',
                    colors: colors,
                    color: color,
                    cambiarFecha: cambiarFecha,
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: fechaSeleccionada,
                    hint: Text(localizations.translate('selectDateHint')),
                    onChanged: (value) {
                      if (value != null) {
                        seleccionarFecha(value);
                      }
                    },
                    items: fechasDisponibles.map((fecha) {
                      return DropdownMenuItem(
                        value: fecha,
                        child: Text(fecha),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (!isLoading && fechaSeleccionada != null)
                    Expanded(
                      child: horariosFiltrados.isNotEmpty
                          ? ListView.builder(
                              itemCount: horariosFiltrados.length,
                              itemBuilder: (context, index) {
                                final clase = horariosFiltrados[index];
                                final esFeriado = clase.feriado;

                                return GestureDetector(
                                  onLongPress: () async {
                                    bool nuevoValor = !esFeriado;

                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("Modificar feriado"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  "¿Querés marcar esta clase como feriado?"),
                                              const SizedBox(height: 10),
                                              SwitchListTile(
                                                value: nuevoValor,
                                                onChanged: (val) {
                                                  nuevoValor = val;
                                                  Navigator.of(context).pop();
                                                },
                                                title: Text(nuevoValor
                                                    ? "Feriado"
                                                    : "Clase normal"),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cancelar"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(context);

                                                await ModificarFeriado
                                                    .cambiarFeriado(
                                                  idClase: clase.id,
                                                  nuevoValor: nuevoValor,
                                                );

                                                setState(() {
                                                  final idx = horariosFiltrados
                                                      .indexWhere((c) =>
                                                          c.id == clase.id);
                                                  if (idx != -1) {
                                                    horariosFiltrados[idx] =
                                                        clase.copyWith(
                                                            feriado:
                                                                nuevoValor);
                                                  }

                                                  final idxAll =
                                                      horariosDisponibles
                                                          .indexWhere((c) =>
                                                              c.id == clase.id);
                                                  if (idxAll != -1) {
                                                    horariosDisponibles[
                                                            idxAll] =
                                                        clase.copyWith(
                                                            feriado:
                                                                nuevoValor);
                                                  }
                                                });
                                              },
                                              child: const Text("Guardar"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: esFeriado
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Card(
                                            color: Colors.amber.shade100,
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.celebration,
                                                      size: 40,
                                                      color: Colors.orange),
                                                  const SizedBox(width: 16),
                                                  const Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "¡Es feriado!",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .deepOrange,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          "No hay clases este día. ¡Disfrutá tu descanso!",
                                                          style: TextStyle(
                                                              fontSize: 16),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Card(
                                            color: colors.surface,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ListTile(
                                                  title: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color: colors
                                                                    .primary,
                                                                width: 1.5),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            color: colors
                                                                .primary
                                                                .withAlpha(10),
                                                          ),
                                                          child: Text(
                                                            clase.hora,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        clase.mails.isNotEmpty
                                                            ? Text(
                                                                localizations
                                                                    .translate(
                                                                        'studentsLabel'),
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              )
                                                            : const Text(
                                                                "Clase vacía",
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                      clase.mails.join(", ")),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      // Remover primero
                                                      SizedBox(
                                                        width: size.width > 600
                                                            ? size.width * 0.15
                                                            : size.width * 0.33,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            mostrarDialogo(
                                                                "remover",
                                                                clase,
                                                                colors,
                                                                scaffoldContext);
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero),
                                                          child: Text(
                                                            localizations.translate(
                                                                'removeUserButton'),
                                                            style: TextStyle(
                                                                fontSize:
                                                                    size.width *
                                                                        0.025),
                                                          ),
                                                        ),
                                                      ),
                                                      // Agregar después
                                                      SizedBox(
                                                        width: size.width > 600
                                                            ? size.width * 0.15
                                                            : size.width * 0.33,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            mostrarDialogo(
                                                                "insertar",
                                                                clase,
                                                                colors,
                                                                scaffoldContext);
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero),
                                                          child: Text(
                                                            localizations.translate(
                                                                'addUserButton'),
                                                            style: TextStyle(
                                                                fontSize:
                                                                    size.width *
                                                                        0.025),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                );
                              })
                          : Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: size.width * 0.2),
                                child: SizedBox(
                                  width: size.width * 0.65,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: color,
                                        size: size.width * 0.12,
                                      ),
                                      SizedBox(height: size.width * 0.02),
                                      // TEXTO cuando no hay clases
                                      Text(
                                        AppLocalizations.of(context).translate(
                                          'noClassesLoaded',
                                          params: {
                                            'day':
                                                _obtenerDia(fechaSeleccionada),
                                            'date': diaMes,
                                          },
                                        ),
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: InformationButon(
          text:
              "1️⃣ Seleccioná una fecha del mes para ver todas las clases de ese día.\n\n"
              "2️⃣ En cada clase vas a poder agregar o quitar alumnos. También podés usar la opción \"x4\" para hacerlo automáticamente en todas las clases iguales del mes (por ejemplo, todos los lunes a la misma hora).\n\n"
              "3️⃣ Si hay un día que no se va a trabajar, podés marcarlo como feriado dejando presionada la clase correspondiente. Es mejor hacerlo antes de cargar alumnos, así se evita incluir ese día.\n\n",
        ),
      );
    });
  }
}
