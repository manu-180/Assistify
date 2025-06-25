// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:assistify/utils/dia_con_fecha.dart';
import 'package:assistify/utils/encontrar_semana.dart';
import 'package:assistify/utils/generar_fechas_del_mes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/subscription/subscription_verifier.dart';
import 'package:assistify/supabase/clases/eliminar_clase.dart';
import 'package:assistify/supabase/modificar_datos/modificar_feriado.dart';
import 'package:assistify/supabase/modificar_datos/modificar_lugar_disponible.dart';
import 'package:assistify/supabase/obtener_datos/obtener_mes.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/obtener_datos/obtener_total_info.dart';
import 'package:assistify/supabase/utiles/generar_id.dart';
import 'package:assistify/utils/contar_dias_en_mes_actual.dart';
import 'package:assistify/utils/utils_barril.dart';
import 'package:assistify/main.dart';
import 'package:intl/intl.dart';
import 'package:assistify/models/clase_models.dart';
import 'package:assistify/widgets/information_buton.dart';
import 'package:assistify/widgets/responsive_appbar.dart';
import 'package:assistify/widgets/snackbar_animado.dart';

import '../widgets/mostrar_dia_segun_fecha.dart';

class GestionDeClasesScreen extends StatefulWidget {
  const GestionDeClasesScreen({super.key, String? taller});

  @override
  State<GestionDeClasesScreen> createState() => _GestionDeClasesScreenState();
}

class _GestionDeClasesScreenState extends State<GestionDeClasesScreen> {
  List<String> fechasDisponibles = [];
  String? fechaSeleccionada;
  List<ClaseModels> clasesDisponibles = [];
  List<ClaseModels> clasesFiltradas = [];
  late BuildContext scaffoldContext;

  bool isLoading = true;
  bool isProcessing = false;
  int mes = 0;

  @override
  void initState() {
    super.initState();
    inicializarDatos();
    // Verificación de Admin / Subscripción
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

  void ordenarClasesPorFechaYHora() {
    clasesFiltradas.sort((a, b) {
      final formatoFecha = DateFormat('dd/MM');
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

      setState(() {
        clasesDisponibles = List<ClaseModels>.from(datos);
        clasesFiltradas = List.from(datos);
        ordenarClasesPorFechaYHora();
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
      clasesFiltradas = clasesDisponibles.where((clase) {
        return clase.fecha == fechaSeleccionada;
      }).toList();
    });
  }

  /// Estos métodos siguen funcionando porque 'lugaresDisponibles' sí es un int no final.
  /// Si lo tuvieras como final, tendrías que usar copyWith igual que capacidad.
  Future<void> agregarLugar(int id) async {
    setState(() {
      final index = clasesFiltradas.indexWhere((clase) => clase.id == id);
      if (index != -1) {
        clasesFiltradas[index].lugaresDisponibles++;
      }
    });
  }

  Future<void> quitarLugar(int id) async {
    setState(() {
      final index = clasesFiltradas.indexWhere((clase) => clase.id == id);
      if (index != -1 && clasesFiltradas[index].lugaresDisponibles > 0) {
        clasesFiltradas[index].lugaresDisponibles--;
      }
    });
  }

  Future<Map<String, dynamic>?> mostrarDialogoConfirmacion(
    BuildContext context,
    String mensaje, {
    required bool esEliminar,
    required ClaseModels clase,
    required List<ClaseModels> clasesDisponibles,
    required List<ClaseModels> clasesFiltradas,
    required String? fechaSeleccionada,
    required void Function(List<ClaseModels> nuevasDisponibles,
            List<ClaseModels> nuevasFiltradas)
        onActualizar,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        if (esEliminar) {
          return _DialogoEliminarClaseConSwitch(
            mensaje: mensaje,
            clase: clase,
            esEliminar: true,
            clasesDisponibles: clasesDisponibles,
            clasesFiltradas: clasesFiltradas,
            fechaSeleccionada: fechaSeleccionada,
            onActualizar: onActualizar,
            scaffoldContext: scaffoldContext,
          );
        } else {
          return DialogoModificarLugarDisponible(
            mensaje: mensaje,
            esAgregar: mensaje.toLowerCase().contains('agregar'),
          );
        }
      },
    );
  }

  String obtenerDia(DateTime fecha) {
    final localizations = AppLocalizations.of(context);
    switch (fecha.weekday) {
      case DateTime.monday:
        return localizations.translate('monday');
      case DateTime.tuesday:
        return localizations.translate('tuesday');
      case DateTime.wednesday:
        return localizations.translate('wednesday');
      case DateTime.thursday:
        return localizations.translate('thursday');
      case DateTime.friday:
        return localizations.translate('friday');
      case DateTime.saturday:
        return localizations.translate('saturday');
      case DateTime.sunday:
        return localizations.translate('sunday');
      default:
        return localizations.translate('unknownDay');
    }
  }

  Future<void> mostrarDialogoAgregarClase(String dia) async {
    final size = MediaQuery.of(context).size;
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final horaController = TextEditingController();
    final lugarController = TextEditingController();

    final localizations = AppLocalizations.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                localizations.translate('addNewClassDialogTitle', params: {
                  'day': dia,
                }),
              ),
              content: isProcessing
                  ? null
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: horaController,
                          decoration: InputDecoration(
                            hintText: localizations.translate('classTimeHint'),
                          ),
                        ),
                        TextField(
                          controller: lugarController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('classCapacityHint'),
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (isProcessing)
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: SizedBox(
                      width: size.width * 0.05,
                      height: size.width * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: size.width * 0.006,
                      ),
                    ),
                    label: Text(
                      localizations.translate('loadingClassesLabel'),
                    ),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      localizations.translate('cancelButtonLabel'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await Future.delayed(const Duration(seconds: 1));
                      if (mounted) {
                        setStateDialog(() {
                          isProcessing = true;
                        });
                      }

                      try {
                        final hora = horaController.text.trim();
                        if (hora.isEmpty || fechaSeleccionada == null) {
                          throw Exception(
                            localizations.translate('invalidTimeOrDateError'),
                          );
                        }

                        final lugarText = lugarController.text.trim();
                        final lugar = int.tryParse(lugarText);

                        if (lugar == null) {
                          throw Exception(
                            localizations.translate('invalidCapacityError'),
                          );
                        }

                        final horaFormatoValido =
                            RegExp(r'^\d{2}:\d{2}$').hasMatch(hora);
                        if (!horaFormatoValido) {
                          throw Exception(
                            localizations.translate('invalidTimeFormatError'),
                          );
                        }

                        final partesHora = hora.split(':');
                        final hh = int.tryParse(partesHora[0]) ?? -1;
                        final mm = int.tryParse(partesHora[1]) ?? -1;

                        if (hh < 0 || hh > 23 || mm < 0 || mm > 59) {
                          throw Exception(
                            localizations.translate('timeOutOfRangeError'),
                          );
                        }

                        final fechaBase =
                            DateFormat('dd/MM/yyyy').parse(fechaSeleccionada!);
                        final firstDayOfMonth =
                            DateTime(fechaBase.year, fechaBase.month, 1);
                        final dayOfWeekSelected = fechaBase.weekday;

                        final difference =
                            (7 + dayOfWeekSelected - firstDayOfMonth.weekday) %
                                7;
                        final firstTargetDate =
                            firstDayOfMonth.add(Duration(days: difference));

                        final mesActual = await ObtenerMes().obtenerMes();

                        for (int i = 0; i < 5; i++) {
                          if (!mounted) break;

                          final fechaSemana =
                              firstTargetDate.add(Duration(days: 7 * i));
                          final fechaStr =
                              DateFormat('dd/MM/yyyy').format(fechaSemana);
                          final diaSemana = obtenerDia(fechaSemana);

                          final existingClass = await supabase
                              .from(taller)
                              .select()
                              .eq('fecha', fechaStr)
                              .eq('hora', hora)
                              .maybeSingle();

                          if (existingClass != null) {
                            if (mounted) {
                              mostrarSnackBarAnimado(
                                context: context,
                                mensaje: localizations.translate(
                                  'classAlreadyExists',
                                  params: {'date': fechaStr, 'time': hora},
                                ),
                              );
                            }
                            continue;
                          } else {
                            if (mounted) {
                              mostrarSnackBarAnimado(
                                context: context,
                                mensaje: localizations.translate(
                                  'classAddedSuccess',
                                  params: {'date': fechaStr, 'time': hora},
                                ),
                              );
                            }
                          }

                          await supabase.from(taller).insert({
                            "id": await GenerarId().generarIdClase(),
                            'semana': EncontrarSemana().obtenerSemana(fechaStr),
                            'dia': diaSemana,
                            'fecha': fechaStr,
                            'hora': hora,
                            'mails': [],
                            'lugar_disponible': lugar,
                            'mes': mesActual,
                            "espera": [],
                            "feriado": false,
                          });
                        }

                        await cargarDatos();

                        if (fechaSeleccionada != null && mounted) {
                          setState(() {
                            clasesFiltradas = clasesDisponibles.where((clase) {
                              return clase.fecha == fechaSeleccionada;
                            }).toList();
                          });
                        }

                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          mostrarSnackBarAnimado(
                            context: context,
                            mensaje: e.toString(),
                            colorFondo: Colors.redAccent,
                          );
                        }
                      } finally {
                        if (mounted) {
                          setStateDialog(() {
                            isProcessing = false;
                          });
                        }
                      }
                    },
                    child: Text(
                      localizations.translate('addButtonLabel'),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> mostrarDialogoModificarFeriado(
      ClaseModels clase, bool feriado) async {
    bool nuevoValor = !feriado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modificar feriado"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("¿Querés marcar esta clase como feriado?"),
              const SizedBox(height: 10),
              SwitchListTile(
                value: nuevoValor,
                onChanged: (val) {
                  nuevoValor = val;
                  Navigator.of(context).pop();
                },
                title: Text(nuevoValor ? "Feriado" : "Clase normal"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await ModificarFeriado.cambiarFeriado(
                  idClase: clase.id,
                  nuevoValor: nuevoValor,
                );

                setState(() {
                  final idx =
                      clasesFiltradas.indexWhere((c) => c.id == clase.id);
                  if (idx != -1) {
                    clasesFiltradas[idx] = clase.copyWith(feriado: nuevoValor);
                  }

                  final idxAll =
                      clasesDisponibles.indexWhere((c) => c.id == clase.id);
                  if (idxAll != -1) {
                    clasesDisponibles[idxAll] =
                        clase.copyWith(feriado: nuevoValor);
                  }
                });
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void cambiarFecha(bool siguiente) {
    setState(() {
      if (fechasDisponibles.isNotEmpty) {
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
        } else {
          fechaSeleccionada = fechasDisponibles[0];
        }
        seleccionarFecha(fechaSeleccionada!);
      } else {
        debugPrint('La lista de fechas disponibles está vacía.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Builder(builder: (context) {
      scaffoldContext = context;
      return Scaffold(
        appBar:
            ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    MostrarDiaSegunFecha(
                      text: fechaSeleccionada ?? '-',
                      colors: colors,
                      color: color,
                      cambiarFecha: cambiarFecha,
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<String>(
                      value: fechaSeleccionada,
                      hint: Text(
                        AppLocalizations.of(context)
                            .translate('selectDateHint'),
                      ),
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
                    const SizedBox(height: 20),
                    if (!isLoading &&
                        fechaSeleccionada != null &&
                        clasesFiltradas.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: clasesFiltradas.length,
                          itemBuilder: (context, index) {
                            final clase = clasesFiltradas[index];
                            final esFeriado = clase.feriado;

                            return GestureDetector(
                              onTap: () {
                                mostrarDialogoModificarFeriado(
                                    clase, esFeriado);
                              },
                              onLongPress: () async {
                                final resultado =
                                    await mostrarDialogoConfirmacion(
                                  context,
                                  AppLocalizations.of(context)
                                      .translate('deleteClassConfirmation'),
                                  esEliminar: true,
                                  clase: clase,
                                  clasesDisponibles: clasesDisponibles,
                                  clasesFiltradas: clasesFiltradas,
                                  fechaSeleccionada: fechaSeleccionada,
                                  onActualizar:
                                      (nuevasDisponibles, nuevasFiltradas) {
                                    setState(() {
                                      clasesDisponibles = nuevasDisponibles;
                                      clasesFiltradas = nuevasFiltradas;
                                    });
                                  },
                                );

                                if (resultado != null &&
                                    resultado is Map<String, dynamic> &&
                                    resultado['confirmado'] == true &&
                                    resultado['eliminadas']
                                        is List<ClaseModels>) {
                                  final mensaje = resultado['mensaje'] ??
                                      'Clases eliminadas';
                                  final eliminadas = resultado['eliminadas']
                                      as List<ClaseModels>;

                                  final detalles = eliminadas
                                      .map((cl) =>
                                          '${cl.dia} ${cl.fecha} a las ${cl.hora}')
                                      .join('\n');
                                  mostrarSnackBarAnimado(
                                    context: context,
                                    mensaje: '$mensaje\n\n$detalles',
                                  );
                                }
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
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.celebration,
                                                  size: 40,
                                                  color: Colors.orange),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "¡Es feriado!",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepOrange,
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
                                        child: InkWell(
                                          onTap: () {
                                            mostrarDialogoModificarFeriado(
                                                clase, esFeriado);
                                          },
                                          onLongPress: () async {
                                            final resultado =
                                                await mostrarDialogoConfirmacion(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'deleteClassConfirmation'),
                                              esEliminar: true,
                                              clase: clase,
                                              clasesDisponibles:
                                                  clasesDisponibles,
                                              clasesFiltradas: clasesFiltradas,
                                              fechaSeleccionada:
                                                  fechaSeleccionada,
                                              onActualizar: (nuevasDisponibles,
                                                  nuevasFiltradas) {
                                                setState(() {
                                                  clasesDisponibles =
                                                      nuevasDisponibles;
                                                  clasesFiltradas =
                                                      nuevasFiltradas;
                                                });
                                              },
                                            );

                                            if (resultado != null &&
                                                resultado
                                                    is Map<String, dynamic> &&
                                                resultado['confirmado'] ==
                                                    true &&
                                                resultado['eliminadas']
                                                    is List<ClaseModels>) {
                                              final mensaje =
                                                  resultado['mensaje'] ??
                                                      'Clases eliminadas';
                                              final eliminadas =
                                                  resultado['eliminadas']
                                                      as List<ClaseModels>;

                                              final detalles = eliminadas
                                                  .map((cl) =>
                                                      '${cl.dia} ${cl.fecha} a las ${cl.hora}')
                                                  .join('\n');

                                              mostrarSnackBarAnimado(
                                                  context: context,
                                                  mensaje:
                                                      '$mensaje\n\n$detalles');
                                            }
                                          },
                                          child: ListTile(
                                            title: Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                'classInfo',
                                                params: {
                                                  'time': clase.hora,
                                                  'availablePlaces': clase
                                                      .lugaresDisponibles
                                                      .toString(),
                                                },
                                              ),
                                            ),
                                            subtitle: clase.mails.isEmpty
                                                ? Text("Sin alumnos")
                                                : Text(clase.mails.join(", ")),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon:  Icon(Icons.add, color: color),
                                                 onPressed: () async {
  final resultado = await mostrarDialogoConfirmacion(
    context,
    AppLocalizations.of(context).translate('addPlaceConfirmation'),
    clase: clase,
    esEliminar: false,
    clasesDisponibles: clasesDisponibles,
    clasesFiltradas: clasesFiltradas,
    fechaSeleccionada: fechaSeleccionada,
    onActualizar: (nuevasDisponibles, nuevasFiltradas) {
      setState(() {
        clasesDisponibles = nuevasDisponibles;
        clasesFiltradas = nuevasFiltradas;
      });
    },
  );

  if (resultado is Map<String, dynamic> &&
      resultado['confirmado'] == true &&
      resultado['cantidad'] != null) {
    final cantidad = resultado['cantidad'] as int;
    for (int i = 0; i < cantidad; i++) {
      await ModificarLugarDisponible().agregarLugarDisponible(clase.id);
      await agregarLugar(clase.id);
    }

    final mensaje = cantidad == 1
        ? 'Se agregó 1 lugar disponible a la clase del ${clase.dia} ${clase.fecha} a las ${clase.hora}'
        : 'Se agregaron $cantidad lugares disponibles a la clase del ${clase.dia} ${clase.fecha} a las ${clase.hora}';

    mostrarSnackBarAnimado(context: context, mensaje: mensaje);
  }
}

                                                ),
                                                IconButton(
                                                  icon:
                                                       Icon(Icons.remove, color: color),
                                                  onPressed: () async {
  final resultado = await mostrarDialogoConfirmacion(
    context,
    AppLocalizations.of(context).translate('removePlaceConfirmation'),
    clase: clase,
    esEliminar: false,
    clasesDisponibles: clasesDisponibles,
    clasesFiltradas: clasesFiltradas,
    fechaSeleccionada: fechaSeleccionada,
    onActualizar: (nuevasDisponibles, nuevasFiltradas) {
      setState(() {
        clasesDisponibles = nuevasDisponibles;
        clasesFiltradas = nuevasFiltradas;
      });
    },
  );

  if (resultado is Map<String, dynamic> &&
      resultado['confirmado'] == true &&
      resultado['cantidad'] != null) {
    final cantidad = resultado['cantidad'] as int;
    int quitados = 0;

    for (int i = 0; i < cantidad; i++) {
      final idx = clasesFiltradas.indexWhere((c) => c.id == clase.id);
      if (idx != -1 && clasesFiltradas[idx].lugaresDisponibles > 0) {
        await ModificarLugarDisponible().removerLugarDisponible(clase.id);
        await quitarLugar(clase.id);
        quitados++;
      }
    }

    if (quitados > 0) {
      final mensaje = quitados == 1
          ? 'Se quitó 1 lugar disponible de la clase del ${clase.dia} ${clase.fecha} a las ${clase.hora}'
          : 'Se quitaron $quitados lugares disponibles de la clase del ${clase.dia} ${clase.fecha} a las ${clase.hora}';

      mostrarSnackBarAnimado(context: context, mensaje: mensaje);
    }
  }
}

                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom:
                  90, // Lo subo un poco para no tapar el FloatingActionButton
              right: 20,
              child: InformationButon(text: '''
1️⃣ Primero seleccioná una fecha en el calendario.
Así el sistema sabe qué día de la semana (por ejemplo "martes") va a usar para crear las clases.

2️⃣ Para crear una nueva clase, presioná el botón "Crear nueva clase".
Vas a tener que ingresar la hora y la cantidad de lugares disponibles.
Se generará automáticamente una clase cada semana en el día seleccionado.

3️⃣ Desde cada clase podés:

➕ Aumentar los lugares disponibles.

➖ Reducir los lugares disponibles.

4️⃣ Si presionás en una clase, podés marcarla como "feriado".
Así se indica que ese día no habrá clases.

5️⃣ Si dejás presionada una clase, podés eliminarla.
Y si activás el switch, se eliminarán todas las clases del mismo día y hora de ese mes.
'''),
            ),
          ],
        ),
        floatingActionButton: SizedBox(
          width: isWide ? size.width * 0.23 : size.width * 0.5,
          child: FloatingActionButton(
            backgroundColor: colors.secondaryContainer,
            onPressed: () {
              if (fechaSeleccionada == null) {
                mostrarSnackBarAnimado(
                  context: context,
                  mensaje: AppLocalizations.of(context)
                      .translate('selectDateBeforeAdding'),
                );

                return;
              }
              mostrarDialogoAgregarClase(
                DiaConFecha().obtenerDiaDeLaSemana(
                  fechaSeleccionada!,
                  AppLocalizations.of(context),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context).translate('createNewClassButton'),
            ),
          ),
        ),
      );
    });
  }
}

class _DialogoConfirmacionConContador extends StatefulWidget {
  final String mensaje;
  final bool esEliminar;

  const _DialogoConfirmacionConContador({
    required this.mensaje,
    required this.esEliminar,
  });

  @override
  State<_DialogoConfirmacionConContador> createState() =>
      _DialogoConfirmacionConContadorState();
}

class _DialogoConfirmacionConContadorState
    extends State<_DialogoConfirmacionConContador> {
  int segundosRestantes = 2;
  late final AppLocalizations localizations;

  @override
  void initState() {
    super.initState();
    if (widget.esEliminar) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          segundosRestantes--;
        });
        if (segundosRestantes == 0) timer.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.translate('confirmationDialogTitle')),
      content: Text(widget.mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizations.translate('noButton')),
        ),
        ElevatedButton(
          onPressed: widget.esEliminar && segundosRestantes > 0
              ? null
              : () => Navigator.of(context).pop(true),
          child: Text(
            widget.esEliminar && segundosRestantes > 0
                ? 'Eliminar ($segundosRestantes)'
                : 'Eliminar',
          ),
        ),
      ],
    );
  }
}

class _DialogoEliminarClaseConSwitch extends StatefulWidget {
  final String mensaje;
  final bool esEliminar;
  final ClaseModels clase;
  final List<ClaseModels> clasesDisponibles;
  final List<ClaseModels> clasesFiltradas;
  final String? fechaSeleccionada;
  final BuildContext scaffoldContext;
  final void Function(List<ClaseModels> nuevasDisponibles,
      List<ClaseModels> nuevasFiltradas) onActualizar;

  const _DialogoEliminarClaseConSwitch({
    required this.mensaje,
    required this.esEliminar,
    required this.clase,
    required this.clasesDisponibles,
    required this.clasesFiltradas,
    required this.fechaSeleccionada,
    required this.onActualizar,
    required this.scaffoldContext,
  });

  @override
  State<_DialogoEliminarClaseConSwitch> createState() =>
      _DialogoEliminarClaseConSwitchState();
}

class _DialogoEliminarClaseConSwitchState
    extends State<_DialogoEliminarClaseConSwitch> {
  int segundosRestantes = 2;
  bool eliminarMultiples = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.esEliminar) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          segundosRestantes--;
        });
        if (segundosRestantes == 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void mostrarSnackBarEliminacion({
    required String titulo,
    required List<ClaseModels> clases,
    required Color colorFondo,
  }) {
    final detalles =
        clases.map((cl) => '${cl.dia} ${cl.fecha} a las ${cl.hora}').join('\n');
    final mensaje = '$titulo:\n\n$detalles';

    ScaffoldMessenger.of(widget.scaffoldContext).hideCurrentSnackBar();

    mostrarSnackBarAnimado(
      context: widget.scaffoldContext,
      mensaje: mensaje,
      colorFondo: colorFondo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return FutureBuilder<int>(
      future: contarDiasEnMesActual(widget.clase.dia.toLowerCase()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AlertDialog(
            content: SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final repeticiones = snapshot.data ?? 0;
        final eliminarText = eliminarMultiples
            ? "Eliminar $repeticiones clases"
            : "Eliminar esta clase";

        return AlertDialog(
          title: Text(localizations.translate('confirmationDialogTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.mensaje),
              const SizedBox(height: 12),
              SwitchListTile(
                value: eliminarMultiples,
                onChanged: (val) {
                  setState(() {
                    eliminarMultiples = val;
                  });
                },
                title: Text(
                  "¿Eliminar ${widget.clase.dia} x$repeticiones?",
                  style: const TextStyle(fontSize: 14.5),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.translate('noButton')),
            ),
            ElevatedButton(
              onPressed: widget.esEliminar && segundosRestantes > 0
                  ? null
                  : () async {
                      final dia = widget.clase.dia;
                      final hora = widget.clase.hora;
                      final id = widget.clase.id;

                      if (eliminarMultiples) {
                        await EliminarClase()
                            .eliminarMuchasClases(dia: dia, hora: hora);
                        final mesActual = await ObtenerMes().obtenerMes();

                        final eliminadas = widget.clasesDisponibles
                            .where((c) =>
                                c.dia == dia &&
                                c.hora == hora &&
                                c.mes == mesActual)
                            .toList();

                        widget.clasesDisponibles.removeWhere((c) =>
                            c.dia == dia &&
                            c.hora == hora &&
                            c.mes == mesActual);

                        final clasesFiltradasActualizadas =
                            widget.fechaSeleccionada != null
                                ? widget.clasesDisponibles
                                    .where((c) =>
                                        c.fecha == widget.fechaSeleccionada)
                                    .toList()
                                : <ClaseModels>[];

                        widget.onActualizar(widget.clasesDisponibles,
                            clasesFiltradasActualizadas);

                        if (!mounted) return;

                        Navigator.of(context).pop({
                          'confirmado': true,
                          'eliminadas': eliminadas,
                          'mensaje':
                              'Se eliminaron ${eliminadas.length} clases',
                        });
                      } else {
                        await EliminarClase().eliminarClase(id);

                        final nuevasDisponibles = widget.clasesDisponibles
                            .where((c) => c.id != id)
                            .toList();
                        final nuevasFiltradas = widget.clasesFiltradas
                            .where((c) => c.id != id)
                            .toList();

                        widget.onActualizar(nuevasDisponibles, nuevasFiltradas);

                        if (!mounted) return;

                        Navigator.of(context).pop({
                          'confirmado': true,
                          'eliminadas': [widget.clase],
                          'mensaje': 'Se eliminó la clase:',
                        });
                      }
                    },
              child: Text(
                segundosRestantes > 0
                    ? '$eliminarText ($segundosRestantes)'
                    : eliminarText,
              ),
            ),
          ],
        );
      },
    );
  }
}

class DialogoModificarLugarDisponible extends StatefulWidget {
  final String mensaje;
  final bool esAgregar;

  const DialogoModificarLugarDisponible({
    required this.mensaje,
    required this.esAgregar,
  });

  @override
  State<DialogoModificarLugarDisponible> createState() =>
      _DialogoModificarLugarDisponibleState();
}

class _DialogoModificarLugarDisponibleState
    extends State<DialogoModificarLugarDisponible> {
  int cantidad = 1;

  void aumentar() {
    setState(() {
      cantidad++;
    });
  }

  void disminuir() {
    if (cantidad > 1) {
      setState(() {
        cantidad--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.translate('confirmationDialogTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.mensaje),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: color),
                onPressed: disminuir,
              ),
              Text(
                '$cantidad',
                style: const TextStyle(fontSize: 20),
              ),
              IconButton(
                icon: Icon(Icons.add, color: color),
                onPressed: aumentar,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(localizations.translate('noButton')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'confirmado': true,
              'cantidad': cantidad,
            });
          },
          child: Text(widget.esAgregar
              ? localizations.translate('addButtonLabel')
              : localizations.translate('removeButtonLabel')),
        ),
      ],
    );
  }
}
