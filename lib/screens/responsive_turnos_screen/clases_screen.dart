// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/subscription/subscription_verifier.dart';
import 'package:taller_ceramica/supabase/obtener_datos/is_admin.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_capacidad_clase.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_lugar_disponible.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_mes.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/generar_fechas_del_mes.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import 'package:taller_ceramica/widgets/shimmer_loader.dart';

class ClasesScreen extends StatefulWidget {
  const ClasesScreen({
    super.key,
  });

  @override
  State<ClasesScreen> createState() => _ClasesScreenState();
}

class _ClasesScreenState extends State<ClasesScreen> {
  List<String> fechasDisponibles = [];
  String semanaSeleccionada = 'semana1';
  String? diaSeleccionado;
  final List<String> semanas = [
    'semana1',
    'semana2',
    'semana3',
    'semana4',
    'semana5'
  ];
  int mesActual = 1;
  bool isLoading = true;
  List<ClaseModels> diasUnicos = [];
  Map<String, List<ClaseModels>> horariosPorDia = {};
  String? avisoDeClasesDisponibles;
  Map<int, int> capacidadCache = {};

  Future<void> cargarDatos() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    setState(() {
      isLoading = true;
    });

    final capacidades =
        await ObtenerCapacidadClase().cargarTodasLasCapacidades();
    for (var capacidad in capacidades) {
      capacidadCache[capacidad['id']] = capacidad['capacidad'];
    }

    final datos = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerClases();

    final datosSemana =
        datos.where((clase) => clase.semana == semanaSeleccionada).toList();

    final dateFormat = DateFormat("dd/MM/yyyy HH:mm");

    datosSemana.sort((a, b) {
      String fechaA = '${a.fecha} ${a.hora}';
      String fechaB = '${b.fecha} ${b.hora}';

      DateTime parsedFechaA = dateFormat.parse(fechaA);
      DateTime parsedFechaB = dateFormat.parse(fechaB);

      return parsedFechaA.compareTo(parsedFechaB);
    });

    final diasSet = <String>{};
    diasUnicos = datosSemana.where((clase) {
      final diaFecha = '${clase.dia} - ${clase.fecha}';
      if (diasSet.contains(diaFecha)) {
        return false;
      } else {
        diasSet.add(diaFecha);
        return true;
      }
    }).toList();

    horariosPorDia = {};
    for (var clase in datosSemana) {
      final diaFecha = '${clase.dia} - ${clase.fecha}';
      horariosPorDia.putIfAbsent(diaFecha, () => []).add(clase);
    }

    final diasConClasesDisponibles = await obtenerDiasConClasesDisponibles();
    if (diasConClasesDisponibles.isEmpty) {
      avisoDeClasesDisponibles =
          AppLocalizations.of(context).translate('noAvailableClasses');
    } else {
      avisoDeClasesDisponibles = AppLocalizations.of(context)
          .translate('availableClasses', params: {
        'days': diasConClasesDisponibles.join(', ')
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> obtenerDiasConClasesDisponibles() async {
  final diasConClases = <String>{};
  final usuarioActivo = Supabase.instance.client.auth.currentUser;
  final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

  // 🔥 Obtener todos los IDs de clases
  final List<int> idsClases = horariosPorDia.values
      .expand((clases) => clases.map((c) => c.id))
      .toList();

  if (idsClases.isEmpty) return []; // Si no hay clases, retornamos una lista vacía

  // 🔥 Construir el filtro con `.or()`
  final String filtroOr = idsClases.map((id) => "id.eq.$id").join(",");

  // 🔥 Consulta única a Supabase
  final response = await Supabase.instance.client
      .from(taller) // Tabla en Supabase
      .select('id, lugar_disponible')
      .or(filtroOr); // Filtra por múltiples IDs

  // 🔹 Convertimos la respuesta en un mapa
  final Map<int, int> lugaresPorClase = {
    for (var row in response) row['id'] as int: row['lugar_disponible'] as int
  };

  // 🔹 Procesamos los datos con los lugares ya en memoria
  for (var entry in horariosPorDia.entries) {
    final dia = entry.key;
    final clases = entry.value;

    for (var clase in clases) {
      final capacidad = capacidadCache[clase.id] ?? 0;
      final mailsLimpios = clase.mails.map((mail) => mail.trim()).toList();
      final menorA24 =
          Calcular24hs().esMenorA0Horas(clase.fecha, clase.hora, mesActual);
      final lugarDisponible = lugaresPorClase[clase.id] ?? 0;

      if (mailsLimpios.length < capacidad && !menorA24 && lugarDisponible > 0) {
        final partesFecha = dia.split(' - ')[1].split('/');
        final diaMes = int.parse(partesFecha[1]);

        if (diaMes == mesActual) {
          final diaSolo = dia.split(' - ')[0]; // Extraer solo el día (ej: "Lunes")
          diasConClases.add(diaSolo);
        }
      }
    }
  }

  return diasConClases.toList();
}



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
        mesActual = mes;
      });

      await cargarDatos();
    } catch (e) {
      debugPrint('Error al inicializar los datos: $e');
    }
  }

  Future<void> mostrarAlertaListaEspera({
    required BuildContext context,
    ClaseModels? clase,
  }) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('waitlistTitle')),
          content:
              Text(AppLocalizations.of(context).translate('waitlistContent')),
          actions: <Widget>[
            TextButton(
              child:
                  Text(AppLocalizations.of(context).translate('cancelButton')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: Text(AppLocalizations.of(context).translate('acceptButton')),
              onPressed: () {
                AgregarUsuario(supabase).agregarUsuarioAListaDeEspera(
                    clase!.id, usuarioActivo!.userMetadata?['fullname']);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void cambiarSemanaAdelante() {
    final indiceActual = semanas.indexOf(semanaSeleccionada);
    final nuevoIndice = (indiceActual + 1) % semanas.length;

    setState(() {
      semanaSeleccionada = semanas[nuevoIndice];
      isLoading = true;
      avisoDeClasesDisponibles = null;
    });

    cargarDatos();
  }

  void cambiarSemanaAtras() {
    final indiceActual = semanas.indexOf(semanaSeleccionada);
    final nuevoIndice = (indiceActual - 1 + semanas.length) % semanas.length;

    setState(() {
      semanaSeleccionada = semanas[nuevoIndice];
      isLoading = true;
      avisoDeClasesDisponibles = null;
    });

    cargarDatos();
  }

  void mostrarConfirmacion(BuildContext context, ClaseModels clase) async {
    final user = Supabase.instance.client.auth.currentUser;

    String mensaje;
    bool mostrarBotonAceptar = false;

    if (user == null) {
      mensaje = AppLocalizations.of(context)
          .translate('loginToEnrollMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    final mailsLimpios = clase.mails.map((mail) => mail.trim()).toList();

    if (mailsLimpios.contains(user.userMetadata?['fullname'])) {
      mensaje = AppLocalizations.of(context)
          .translate('alreadyEnrolledMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    final triggerAlert = await ObtenerAlertTrigger()
        .alertTrigger(user.userMetadata?['fullname']);
    final clasesDisponibles = await ObtenerClasesDisponibles()
        .clasesDisponibles(user.userMetadata?['fullname']);

    if (!context.mounted) return;

    if (triggerAlert > 0 && clasesDisponibles == 0) {
      mensaje = AppLocalizations.of(context)
          .translate('cannotRecoverClassMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    if (clasesDisponibles == 0) {
      mensaje = AppLocalizations.of(context)
          .translate('noCreditsAvailableMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    mensaje = AppLocalizations.of(context).translate(
      'confirmEnrollMessage',
      params: {'day': clase.dia, 'time': clase.hora},
    );
    mostrarBotonAceptar = true;

    if (context.mounted) {
      _mostrarDialogo(context, mensaje, mostrarBotonAceptar, clase, user);
    }
  }

  void _mostrarDialogo(
      BuildContext context, String mensaje, bool mostrarBotonAceptar,
      [ClaseModels? clase, dynamic user]) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _obtenerTituloDialogo(mensaje),
          ),
          content: Text(
            mensaje,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('cancelButton')),
            ),
            if (mostrarBotonAceptar)
              ElevatedButton(
                onPressed: () {
                  if (clase != null && user != null) {
                    manejarSeleccionClase(
                        clase, user.userMetadata?['fullname'] ?? '');
                    ModificarAlertTrigger().resetearAlertTrigger(
                        user.userMetadata?['fullname'] ?? '');
                  }
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('acceptButton')),
              ),
          ],
        );
      },
    );
  }

  void manejarSeleccionClase(ClaseModels clase, String user) async {
    await AgregarUsuario(supabase)
        .agregarUsuarioAClase(clase.id, user, false, clase);

    setState(() {
      cargarDatos();
    });
  }

  String _obtenerTituloDialogo(String mensaje) {
    if (mensaje ==
        AppLocalizations.of(context).translate('loginRequiredMessage')) {
      return AppLocalizations.of(context).translate('loginTitle');
    } else if (mensaje ==
        AppLocalizations.of(context).translate('checkInMyClassesMessage')) {
      return AppLocalizations.of(context).translate('alreadyEnrolledTitle');
    } else if (mensaje ==
            AppLocalizations.of(context).translate('noCreditsMessage') ||
        mensaje ==
            AppLocalizations.of(context).translate('cannotRecoverMessage') ||
        mensaje ==
            AppLocalizations.of(context).translate('cannotEnrollMessage')) {
      return AppLocalizations.of(context).translate('cannotEnrollTitle');
    } else {
      return AppLocalizations.of(context).translate('confirmEnrollmentTitle');
    }
  }

  void seleccionarDia(String dia) {
    setState(() {
      diaSeleccionado = dia;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    double paddingSize = screenWidth * 0.05;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: screenWidth > 600),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(paddingSize, 20, paddingSize, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppLocalizations.of(context).translate('classScheduleInfo'),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: screenWidth * 0.04),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _SemanaNavigation(
            semanaSeleccionada: semanaSeleccionada,
            cambiarSemanaAdelante: cambiarSemanaAdelante,
            cambiarSemanaAtras: cambiarSemanaAtras,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: isLoading
                      ? Column(
                          children: List.generate(
                              5,
                              (index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: SizedBox(
                                      height: screenWidth * 0.113,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Center(
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: LinearProgressIndicator(
                                                minHeight: 2.2,
                                              )),
                                        ),
                                      ),
                                    ),
                                  )),
                        )
                      : _DiaSelection(
  diasUnicos: diasUnicos,
  seleccionarDia: seleccionarDia,
  fechasDisponibles: fechasDisponibles,
  mesActual: mesActual,
  cambiarSemanaAdelante: cambiarSemanaAdelante,
),

                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSize),
                    child: diaSeleccionado != null
                        ? isLoading
                            ? const SizedBox()
                            : ListView.builder(
                                itemCount:
                                    horariosPorDia[diaSeleccionado]?.length ??
                                        0,
                                itemBuilder: (context, index) {
                                  final clase =
                                      horariosPorDia[diaSeleccionado]![index];
                                  return FutureBuilder<Widget>(
                                    future: construirBotonHorario(
                                        clase, capacidadCache),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(AppLocalizations.of(context)
                                            .translate('errorMessage',
                                                params: {
                                              'error': snapshot.error.toString()
                                            }));
                                      } else {
                                        return snapshot.data ??
                                            const SizedBox();
                                      }
                                    },
                                  );
                                },
                              )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: paddingSize, vertical: 20),
            child: avisoDeClasesDisponibles != null && !isLoading
                ? _AvisoDeClasesDisponibles(
                    colors: colors,
                    color: color,
                    text: avisoDeClasesDisponibles!,
                  )
                : ShimmerLoading(
                    brillo: colors.primary.withAlpha(40),
                    color: colors.primary.withAlpha(120),
                    height: screenWidth * 0.19,
                    width: screenWidth * 0.9,
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<Widget> construirBotonHorario(
    ClaseModels clase, Map<int, int> capacidadCache) async {
  final partesFecha = clase.fecha.split('/');
  final diaMes = '${partesFecha[0]}/${partesFecha[1]}';
  final diaYHora = '${clase.dia} $diaMes - ${clase.hora}';

  final capacidad = capacidadCache[clase.id] ?? 0;
  final estaLlena = clase.mails.length >= capacidad;

  final screenWidth = MediaQuery.of(context).size.width;
  final esAdmin = await IsAdmin().admin();

  return Column(
    children: [
      SizedBox(
        width: screenWidth * 0.7,
        height: screenWidth * 0.12,
        child: GestureDetector(
          child: ElevatedButton(
            onPressed: esAdmin
                ? () async {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            clase.mails.isEmpty
                                ? AppLocalizations.of(context).translate('noStudents')
                                : AppLocalizations.of(context).translate(
                                    'studentsInClass',
                                    params: {'students': clase.mails.join(', ')},
                                  ),
                          ),
                          duration: const Duration(seconds: 5),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    }
                  }
                : ((estaLlena ||
                        Calcular24hs().esMenorA0Horas(
                            clase.fecha, clase.hora, mesActual) ||
                        clase.lugaresDisponibles <= 0))
                    ? null
                    : () async {
                        if (context.mounted) {
                          mostrarConfirmacion(context, clase);
                        }
                      },
            style: ButtonStyle(
              
              backgroundColor: WidgetStateProperty.all(
                estaLlena ||
                        Calcular24hs().esMenorA0Horas(
                            clase.fecha, clase.hora, mesActual) ||
                        clase.lugaresDisponibles <= 0
                    ? Colors.grey.shade400
                    : Colors.green,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03)),
              ),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
            
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  diaYHora,
                  style: TextStyle(fontSize: screenWidth * 0.032, color: Colors.white),
                ),
              ],
            ),
          ),
          onLongPress: () {
            mostrarAlertaListaEspera(context: context, clase: clase);
          },
        ),
      ),
      const SizedBox(height: 18),
    ],
  );
}
}

class _AvisoDeClasesDisponibles extends StatelessWidget {
  const _AvisoDeClasesDisponibles({
    required this.text,
    required this.colors,
    required this.color,
  });

  final ColorScheme colors;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.secondaryContainer,
            colors.primary.withAlpha(70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info,
            color: color,
            size: screenWidth * 0.08,
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemanaNavigation extends StatelessWidget {
  final String semanaSeleccionada;
  final VoidCallback cambiarSemanaAdelante;
  final VoidCallback cambiarSemanaAtras;

  const _SemanaNavigation({
    required this.semanaSeleccionada,
    required this.cambiarSemanaAdelante,
    required this.cambiarSemanaAtras,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: cambiarSemanaAtras,
            icon: Icon(
              Icons.arrow_left,
              size: screenWidth * 0.07,
            ),
          ),
          SizedBox(width: screenWidth * 0.12),
          IconButton(
            onPressed: cambiarSemanaAdelante,
            icon: Icon(
              Icons.arrow_right,
              size: screenWidth * 0.07,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaSelection extends StatelessWidget {
  final List<ClaseModels> diasUnicos;
  final Function(String) seleccionarDia;
  final List<String> fechasDisponibles;
  final int mesActual;
  final VoidCallback cambiarSemanaAdelante;

  const _DiaSelection({
    required this.diasUnicos,
    required this.seleccionarDia,
    required this.fechasDisponibles,
    required this.mesActual,
    required this.cambiarSemanaAdelante,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Si no hay datos en diasUnicos, se pasa automáticamente a la siguiente semana.
    if (diasUnicos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cambiarSemanaAdelante(); // Cambiar a la siguiente semana.
      });
      return const SizedBox.shrink(); // Evitar mostrar contenido innecesario.
    }

    return ListView.builder(
      itemCount: diasUnicos.length,
      itemBuilder: (context, index) {
        final clase = diasUnicos[index];
        final partesFecha = clase.fecha.split('/');
        final diaMes = '${partesFecha[0]}/${partesFecha[1]}';
        final diaMesAnio = '${clase.dia} - ${clase.fecha}';

        final diaFecha = '${clase.dia} - $diaMes';

        final filteredFechas = fechasDisponibles.where((dateString) {
          final partes = dateString.split('/');
          final fecha = DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );

          return fecha.month == mesActual;
        }).toList();

        if (filteredFechas.contains(clase.fecha)) {
          return Column(
            children: [
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.053,
                child: ElevatedButton(
                  onPressed: () => seleccionarDia(diaMesAnio),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  child: Text(
                    diaFecha,
                    style: TextStyle(fontSize: screenWidth * 0.032),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              )
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
