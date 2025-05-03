// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/subscription/subscription_verifier.dart';
import 'package:taller_ceramica/supabase/clases/eliminar_clase.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_feriado.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_lugar_disponible.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_mes.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/supabase/utiles/generar_id.dart';
import 'package:taller_ceramica/utils/utils_barril.dart';
import 'package:taller_ceramica/main.dart';
import 'package:intl/intl.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/widgets/information_buton.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

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

  // Diálogo de confirmación
  Future<bool?> mostrarDialogoConfirmacion(
      BuildContext context, String mensaje) {
    final localizations = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('confirmationDialogTitle')),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.translate('noButton')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations.translate('yesButton')),
            ),
          ],
        );
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
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations.translate(
                                        'classAlreadyExists',
                                        params: {
                                          'date': fechaStr,
                                          'time': hora
                                        }),
                                  ),
                                ),
                              );
                            }
                            continue;
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations.translate('classAddedSuccess',
                                        params: {
                                          'date': fechaStr,
                                          'time': hora
                                        }),
                                  ),
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
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
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
                AppLocalizations.of(context).translate('selectDateHint'),
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
                      onLongPress: () {
                        mostrarDialogoModificarFeriado(clase, esFeriado);
                      },
                      child: esFeriado
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                color: Colors.amber.shade100,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.celebration,
                                          size: 40, color: Colors.orange),
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
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "No hay clases este día. ¡Disfrutá tu descanso!",
                                              style: TextStyle(fontSize: 16),
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
                                  onLongPress: () {
                                    mostrarDialogoModificarFeriado(
                                        clase, esFeriado);
                                  },
                                  child: ListTile(
                                    title: Text(
                                      AppLocalizations.of(context).translate(
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
                                          icon: const Icon(Icons.add),
                                          onPressed: () async {
                                            bool? respuesta =
                                                await mostrarDialogoConfirmacion(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'addPlaceConfirmation'),
                                            );
                                            if (respuesta == true) {
                                              agregarLugar(clase.id);
                                              ModificarLugarDisponible()
                                                  .agregarLugarDisponible(
                                                      clase.id);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () async {
                                            bool? respuesta =
                                                await mostrarDialogoConfirmacion(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'removePlaceConfirmation'),
                                            );
                                            if (respuesta == true &&
                                                clase.lugaresDisponibles > 0) {
                                              quitarLugar(clase.id);
                                              ModificarLugarDisponible()
                                                  .removerLugarDisponible(
                                                      clase.id);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            bool? respuesta =
                                                await mostrarDialogoConfirmacion(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'deleteClassConfirmation'),
                                            );
                                            if (respuesta == true) {
                                              setState(() {
                                                clasesFiltradas
                                                    .removeAt(index);
                                                EliminarClase().eliminarClase(
                                                    clase.id);
                                              });
                                            }
                                          },
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
      bottom: 90, // Lo subo un poco para no tapar el FloatingActionButton
      right: 20,
      child: InformationButon(
        text: 
        '''
1️⃣ Primero seleccioná una fecha en el calendario.
Así el sistema sabe qué día de la semana (por ejemplo "martes") va a usar para crear las clases.

2️⃣ Para crear una nueva clase, presioná el botón "Crear nueva clase".
Vas a tener que ingresar la hora y la cantidad de lugares disponibles.
Se generará automáticamente una clase cada semana en el día seleccionado.

3️⃣ Desde cada clase podés:

➕ Aumentar los lugares disponibles.

➖ Reducir los lugares disponibles.

🗑️ Eliminar la clase.

4️⃣ Si mantenés presionada una clase, podés marcar esa clase como "feriado".
Así se indica que ese día no habrá clases.
'''
      ),
    ),
  ],
),

      floatingActionButton: 

    SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: FloatingActionButton(
        backgroundColor: colors.secondaryContainer,
        onPressed: () {
          if (fechaSeleccionada == null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)
                      .translate('selectDateBeforeAdding'),
                ),
              ),
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
  }
}
