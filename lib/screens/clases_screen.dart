// ignore_for_file: use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/subscription/subscription_verifier.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_feriado.dart';
import 'package:taller_ceramica/supabase/obtener_datos/is_admin.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_mes.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/generar_fechas_del_mes.dart';
import 'package:taller_ceramica/widgets/information_buton.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import 'package:taller_ceramica/widgets/shimmer_loader.dart';

class ClasesScreen extends ConsumerStatefulWidget {
  const ClasesScreen({super.key, String? taller});

  @override
  ConsumerState<ClasesScreen> createState() => ClasesScreenState();
}

class ClasesScreenState extends ConsumerState<ClasesScreen> {
  bool isLoading = true;
  int mesActual = 1;
  String semanaSeleccionada = 'semana1';
  String? diaSeleccionado;

  List<String> fechasDisponibles = [];
  final List<String> semanas = [
    'semana1',
    'semana2',
    'semana3',
    'semana4',
    'semana5',
  ];

  List<ClaseModels> diasUnicos = [];
  Map<String, List<ClaseModels>> horariosPorDia = {};
  final Map<String, List<ClaseModels>> _cachePorSemana = {};
  List<ClaseModels> clasesDisponibles = [];
  List<ClaseModels> clasesFiltradas = [];

  String? avisoDeClasesDisponibles;
  String? avisoAnterior;
  bool esAdmin = false;

  Future<void> cargarDatos({bool intentoDesdeOtraSemana = false}) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    setState(() => isLoading = true);

    if (_cachePorSemana.containsKey(semanaSeleccionada)) {
      final datosSemana = _cachePorSemana[semanaSeleccionada]!;

      _procesarDatosSemana(datosSemana);
      _generarAvisoConDatosLocales();
      setState(() => isLoading = false);
      _actualizarClasesDisponibles();

      if (datosSemana.isEmpty && !intentoDesdeOtraSemana) {
        // 👇 Volvemos a intentar con la siguiente semana
        cambiarSemanaAdelante(forzar: true);
      } else if (datosSemana.isEmpty && intentoDesdeOtraSemana) {
        // 👇 Ya intentamos una vez y sigue vacío: mostrar alerta
        _mostrarDialogoSinClases(taller);
      }

      return;
    }

    // Si no está cacheada, seguimos
    final datos = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerClases();

    final datosSemana =
        datos.where((clase) => clase.semana == semanaSeleccionada).toList();

    _cachePorSemana[semanaSeleccionada] = datosSemana;

    _procesarDatosSemana(datosSemana);
    await _actualizarClasesDisponibles();
    setState(() => isLoading = false);

    if (datosSemana.isEmpty && !intentoDesdeOtraSemana) {
      cambiarSemanaAdelante(forzar: true);
    } else if (datosSemana.isEmpty && intentoDesdeOtraSemana) {
      _mostrarDialogoSinClases(taller);
    }
  }

  void precargarTodasLasSemanas() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final datos = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerClases();

    for (var semana in semanas) {
      if (!_cachePorSemana.containsKey(semana)) {
        final datosSemana =
            datos.where((clase) => clase.semana == semana).toList();
        _cachePorSemana[semana] = datosSemana;
      }
    }
  }

  Future<void> _actualizarClasesDisponibles() async {
    final diasConClasesDisponibles = await obtenerDiasConClasesDisponibles();

    avisoAnterior = avisoDeClasesDisponibles; // 💾 guardamos el valor viejo

    if (diasConClasesDisponibles.isEmpty) {
      avisoDeClasesDisponibles =
          AppLocalizations.of(context).translate('noAvailableClasses');
    } else {
      avisoDeClasesDisponibles = AppLocalizations.of(context).translate(
          'availableClasses',
          params: {'days': diasConClasesDisponibles.join(', ')});
    }

    // ⚠️ Requiere rebuild para reflejar el cambio
    if (mounted) setState(() {});
  }

  void _generarAvisoConDatosLocales() {
    final dias =
        horariosPorDia.keys.map((e) => e.split(' - ')[0]).toSet().toList();

    if (dias.isEmpty) {
      avisoDeClasesDisponibles =
          AppLocalizations.of(context).translate('noAvailableClasses');
    } else {
      avisoDeClasesDisponibles = AppLocalizations.of(context)
          .translate('availableClasses', params: {'days': dias.join(', ')});
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

    if (idsClases.isEmpty)
      return []; // Si no hay clases, retornamos una lista vacía

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
        final menorA24 =
            Calcular24hs().esMenorA0Horas(clase.fecha, clase.hora, mesActual);
        final lugarDisponible = lugaresPorClase[clase.id] ?? 0;

        if (!menorA24 && lugarDisponible > 0 && clase.feriado == false) {
          final partesFecha = dia.split(' - ')[1].split('/');
          final diaMes = int.parse(partesFecha[1]);

          if (diaMes == mesActual) {
            final diaSolo =
                dia.split(' - ')[0]; // Extraer solo el día (ej: "Lunes")
            diasConClases.add(diaSolo);
          }
        }
      }
    }

    return diasConClases.toList();
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
                final diaClave = '${clase.dia} - ${clase.fecha}';
if (horariosPorDia.containsKey(diaClave)) {
  final idx = horariosPorDia[diaClave]!
      .indexWhere((c) => c.id == clase.id);
  if (idx != -1) {
    horariosPorDia[diaClave]![idx] =
        clase.copyWith(feriado: nuevoValor);
  }
}

              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    inicializarDatos();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
    _cargarEsAdmin();
  }

  void _cargarEsAdmin() async {
    esAdmin = await IsAdmin().admin();
    if (mounted) setState(() {}); // para que actualice si cambia algo
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
      precargarTodasLasSemanas(); // precarga las demás semanas en segundo plano
    } catch (e) {
      debugPrint('Error al inicializar los datos: $e');
    }
  }

  void _procesarDatosSemana(List<ClaseModels> datosSemana) {
    final dateFormat = DateFormat("dd/MM/yyyy HH:mm");

    datosSemana.sort((a, b) {
      final fechaA = dateFormat.parse('${a.fecha} ${a.hora}');
      final fechaB = dateFormat.parse('${b.fecha} ${b.hora}');
      return fechaA.compareTo(fechaB);
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
              child:
                  Text(AppLocalizations.of(context).translate('acceptButton')),
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

  void cambiarSemanaAdelante({bool forzar = false}) {
    final indiceActual = semanas.indexOf(semanaSeleccionada);
    final nuevoIndice = (indiceActual + 1) % semanas.length;

    setState(() {
      semanaSeleccionada = semanas[nuevoIndice];
      isLoading = true;
      avisoDeClasesDisponibles = null;
    });

    cargarDatos(intentoDesdeOtraSemana: forzar);
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

  void _mostrarDialogoSinClases(String taller) {

    final usuarioActivo = Supabase.instance.client.auth.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin clases registradas'),
        content: const Text('Primero debes cargar tus clases.'),
        actions: [
          usuarioActivo!.userMetadata?["admin"] ?
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ):
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          usuarioActivo .userMetadata?["admin"] ?
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/gestionclases/$taller');
            },
            child: const Text('Ir a gestión'),
          ):
          SizedBox()
        ],
      ),
    );
  }

  void mostrarConfirmacion(BuildContext context, ClaseModels clase) async {
    final user = Supabase.instance.client.auth.currentUser;

    String mensaje;
    bool mostrarBotonAceptar = false;

    if (user == null) {
      mensaje = AppLocalizations.of(context).translate('loginToEnrollMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    final mailsLimpios = clase.mails.map((mail) => mail.trim()).toList();

    if (mailsLimpios.contains(user.userMetadata?['fullname'])) {
      mensaje =
          AppLocalizations.of(context).translate('alreadyEnrolledMessage');
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
      mensaje =
          AppLocalizations.of(context).translate('cannotRecoverClassMessage');
      if (context.mounted) {
        _mostrarDialogo(context, mensaje, mostrarBotonAceptar);
      }
      return;
    }

    if (clasesDisponibles == 0) {
      mensaje =
          AppLocalizations.of(context).translate('noCreditsAvailableMessage');
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
              child:
                  Text(AppLocalizations.of(context).translate('cancelButton')),
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
                child: Text(
                    AppLocalizations.of(context).translate('acceptButton')),
              ),
          ],
        );
      },
    );
  }

  void manejarSeleccionClase(ClaseModels clase, String user) async {
    await AgregarUsuario(supabase)
        .agregarUsuarioAClase(clase.id, user, false, clase);

    // Borrar solo el caché de la semana actual
    _cachePorSemana.remove(semanaSeleccionada);

    await cargarDatos();
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
    final size = MediaQuery.of(context).size;

    double paddingSize = size.width * 0.05;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
            size.width * 0.03, size.height * 0.06, size.width * 0.03, 0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, size.height * 0.06),
              child: (avisoDeClasesDisponibles ?? avisoAnterior) != null
                  ? _AvisoDeClasesDisponibles(
                      colors: colors,
                      color: color,
                      text: (avisoDeClasesDisponibles ?? avisoAnterior)!,
                    )
                  : ShimmerLoading(
                      brillo: colors.primary.withAlpha(40),
                      color: colors.primary.withAlpha(120),
                      height: size.width * 0.19,
                      width: size.width * 0.9,
                    ),
            ),
            SemanaNavigation(
              semanaSeleccionada: semanaSeleccionada,
              cambiarSemanaAdelante: cambiarSemanaAdelante,
              cambiarSemanaAtras: cambiarSemanaAtras,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: isLoading
                        ? Column(
                            children: List.generate(
                                5,
                                (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: SizedBox(
                                        height: size.width * 0.113,
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
                                    return construirBotonHorario(clase);
                                  },
                                )
                          : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: InformationButon(
          text:
              "1️⃣ Vas a ver botones de lunes a viernes. Tocá el día que te interese."
              "\n\n2️⃣ A la derecha se mostrarán los horarios para ese día. Si hay cupo, podés inscribirte tocando el botón verde."
              "\n\n3️⃣ Si la clase está llena, podés dejar el dedo presionado para unirte a la lista de espera."
              " Si un alumno cancela, y vos tenés crédito disponible, vas a ser agregado automáticamente y se te avisará por WhatsApp."),
    );
  }

  Widget construirBotonHorario(ClaseModels clase) {
    final partesFecha = clase.fecha.split('/');
    final diaMes = '${partesFecha[0]}/${partesFecha[1]}';
    final diaYHora = '${clase.dia} $diaMes - ${clase.hora}';
    final screenWidth = MediaQuery.of(context).size.width;

    // 👉 Si es feriado, mostramos una tarjeta especial
    if (clase.feriado) {
      return Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: GestureDetector(
    onLongPress: esAdmin
        ? () => mostrarDialogoModificarFeriado(clase, clase.feriado)
        : null,
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
            Icon(Icons.celebration,
                size: screenWidth * 0.08, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "¡Es feriado!",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

    }

    // 🔁 Caso normal: clase habilitada o deshabilitada
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
                                  ? AppLocalizations.of(context)
                                      .translate('noStudents')
                                  : AppLocalizations.of(context).translate(
                                      'studentsInClass',
                                      params: {
                                        'students': clase.mails.join(', ')
                                      },
                                    ),
                            ),
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                      }
                    }
                  : ((Calcular24hs().esMenorA0Horas(
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
                    style: TextStyle(
                        fontSize: screenWidth * 0.032, color: Colors.white),
                  ),
                ],
              ),
            ),
            onLongPress: () {
              final usuarioActivo =
                  Supabase.instance.client.auth.currentUser;
              usuarioActivo!.userMetadata?['admin'] ?
              mostrarDialogoModificarFeriado(clase, clase.feriado) :
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

class SemanaNavigation extends StatefulWidget {
  final String semanaSeleccionada;
  final VoidCallback cambiarSemanaAdelante;
  final VoidCallback cambiarSemanaAtras;

  const SemanaNavigation({
    super.key,
    required this.semanaSeleccionada,
    required this.cambiarSemanaAdelante,
    required this.cambiarSemanaAtras,
  });

  @override
  State<SemanaNavigation> createState() => _SemanaNavigationState();
}

class _SemanaNavigationState extends State<SemanaNavigation> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final color = Theme.of(context).colorScheme;

    final semanas = ['semana1', 'semana2', 'semana3', 'semana4', 'semana5'];
    final indiceSeleccionado = semanas.indexOf(widget.semanaSeleccionada);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: widget.cambiarSemanaAtras,
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: screenWidth * 0.07,
            color: color.primary,
          ),
          padding: EdgeInsets.zero, // <- Esto elimina el espacio del ícono
          visualDensity: VisualDensity.compact, // <- Esto ajusta aún más
        ),
        Row(
          children: List.generate(semanas.length, (index) {
            final bool isActive = index == indiceSeleccionado;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: screenWidth * 0.032,
              height: screenWidth * 0.02,
              decoration: BoxDecoration(
                color: isActive ? color.primary : Colors.transparent,
                border: Border.all(
                  color: color.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        IconButton(
          onPressed: widget.cambiarSemanaAdelante,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: screenWidth * 0.07,
            color: color.primary,
          ),
          padding: EdgeInsets.zero, // <- Esto elimina el espacio del ícono
          visualDensity: VisualDensity.compact, // <-
        ),
      ],
    );
  }
}

class _DiaSelection extends StatefulWidget {
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
  State<_DiaSelection> createState() => _DiaSelectionState();
}

class _DiaSelectionState extends State<_DiaSelection> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final filteredFechas = widget.fechasDisponibles.where((dateString) {
      final partes = dateString.split('/');
      final fecha = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
      return fecha.month == widget.mesActual;
    }).toList();

    final diasParaMostrar = widget.diasUnicos.where((clase) {
      return filteredFechas.contains(clase.fecha);
    }).toList();

    return ListView.builder(
      itemCount: diasParaMostrar.length,
      itemBuilder: (context, index) {
        final clase = diasParaMostrar[index];
        final partesFecha = clase.fecha.split('/');
        final diaMes = '${partesFecha[0]}/${partesFecha[1]}';
        final diaMesAnio = '${clase.dia} - ${clase.fecha}';

        return Column(
          children: [
            SizedBox(
              width: screenWidth * 0.99,
              height: screenHeight * 0.053,
              child: ElevatedButton(
                onPressed: () => widget.seleccionarDia(diaMesAnio),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
                child: Text(
                  '${clase.dia} - $diaMes',
                  style: TextStyle(fontSize: screenWidth * 0.032),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
