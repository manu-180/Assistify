// ignore_for_file: use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assistify/subscription/subscription_verifier.dart';
import 'package:assistify/supabase/obtener_datos/obtener_mes.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/main.dart';
import 'package:assistify/utils/utils_barril.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/models/clase_models.dart';
import 'package:assistify/providers/auth_notifier.dart';
import 'package:assistify/widgets/information_buton.dart';
import 'package:assistify/widgets/responsive_appbar.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/widgets/titulo_seleccion.dart';

class MisClasesScreen extends ConsumerStatefulWidget {
  const MisClasesScreen({super.key, String? taller});

  @override
  ConsumerState<MisClasesScreen> createState() => MisClasesScreenState();
}

class MisClasesScreenState extends ConsumerState<MisClasesScreen> {
  List<ClaseModels> clasesDelUsuario = [];
  List<ClaseModels> listaDeEsperaDelUsuario = [];
  int mesActual = 1;
  int _recargaCreditos = 0;

  @override
  void initState() {
    super.initState();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
    cargarMesActual();
    final user = ref.read(authProvider);
    if (user != null) {
      cargarClasesOrdenadasPorProximidad(user.userMetadata?['fullname']);
    }
  }

  void mostrarCancelacion(
      BuildContext context, ClaseModels clase, bool esListaDeEspera) {
    final user = Supabase.instance.client.auth.currentUser;
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('confirmCancellation')),
          content: Text(
            esListaDeEspera
                ? localizations.translate('cancelWaitlist',
                    params: {'day': clase.dia, 'time': clase.hora})
                : Calcular24hs().esMayorA24Horas(clase.fecha, clase.hora)
                    ? localizations.translate('cancelClassRefund',
                        params: {'day': clase.dia, 'time': clase.hora})
                    : localizations.translate('cancelClassNoRefund',
                        params: {'day': clase.dia, 'time': clase.hora}),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.translate('cancelButton')),
            ),
            ElevatedButton(
              onPressed: () {
                if (esListaDeEspera) {
                  cancelarClaseEnListaDeEspera(
                      clase.id, user?.userMetadata?['fullname']);
                } else {
                  cancelarClase(clase.id, user?.userMetadata?['fullname']);
                }
                Navigator.of(context).pop();
              },
              child: Text(localizations.translate('acceptButton')),
            ),
          ],
        );
      },
    );
  }

  void cancelarClase(int claseId, String fullname) async {
    final clase = clasesDelUsuario.firstWhere((clase) => clase.id == claseId);
    clase.mails.remove(fullname);

    await RemoverUsuario(supabase)
        .removerUsuarioDeClase(claseId, fullname, false);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      clasesDelUsuario = clasesDelUsuario
          .where((clase) => clase.mails.contains(fullname))
          .toList();
      _recargaCreditos++;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (mounted) {
      final mensaje = AppLocalizations.of(context).translate(
        'classCancelled',
        params: {
          'dia': clase.dia,
          'fecha': clase.fecha,
          'hora': clase.hora,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: SlideInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }
  }

  void cancelarClaseEnListaDeEspera(int claseId, String fullname) async {
    final clase =
        listaDeEsperaDelUsuario.firstWhere((clase) => clase.id == claseId);
    clase.espera.remove(fullname);
    setState(() {
      listaDeEsperaDelUsuario = listaDeEsperaDelUsuario
          .where((clase) => clase.espera.contains(fullname))
          .toList();
    });
    await RemoverUsuario(supabase)
        .removerUsuarioDeListaDeEspera(claseId, fullname);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (mounted) {
      final mensaje = AppLocalizations.of(context).translate(
        'waitlistCancelled',
        params: {
          'dia': clase.dia,
          'fecha': clase.fecha,
          'hora': clase.hora,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: SlideInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> cargarMesActual() async {
    try {
      final int mes = await ObtenerMes().obtenerMes();
      if (mounted) {
        setState(() {
          mesActual = mes;
        });
      }
    } catch (e) {
      debugPrint('Error al obtener el mes actual: $e');
    }
  }

  Future<void> cargarClasesOrdenadasPorProximidad(String fullname) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final datos = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerClases();

    final dateFormat = DateFormat("dd/MM/yyyy HH:mm");

    final clasesUsuario = datos.where((clase) {
      return clase.mails.contains(fullname);
    }).toList();

    clasesUsuario.sort((a, b) {
      final fechaHoraA = '${a.fecha} ${a.hora}';
      final fechaHoraB = '${b.fecha} ${b.hora}';

      final dateTimeA = dateFormat.parse(fechaHoraA);
      final dateTimeB = dateFormat.parse(fechaHoraB);

      final ahora = DateTime.now();
      final diffA = dateTimeA.difference(ahora).inMilliseconds;
      final diffB = dateTimeB.difference(ahora).inMilliseconds;

      return diffA.compareTo(diffB);
    });

    final listaEspera = datos.where((clase) {
      return clase.espera.contains(fullname);
    }).toList();

    listaEspera.sort((a, b) {
      final fechaHoraA = '${a.fecha} ${a.hora}';
      final fechaHoraB = '${b.fecha} ${b.hora}';

      final dateTimeA = dateFormat.parse(fechaHoraA);
      final dateTimeB = dateFormat.parse(fechaHoraB);

      final ahora = DateTime.now();
      final diffA = dateTimeA.difference(ahora).inMilliseconds;
      final diffB = dateTimeB.difference(ahora).inMilliseconds;

      return diffA.compareTo(diffB);
    });

    listaDeEsperaDelUsuario = listaEspera.cast<ClaseModels>();
    clasesDelUsuario = clasesUsuario.cast<ClaseModels>();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final color = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
        appBar:
            ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
        body: Center(
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
                          localizations.translate('loginToViewClasses'),
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                              fontFamily: "oxanium"),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TituloSeleccion(
                          texto:
                              'Para recuperar la clase debes cancelar con más de 24 hs de anticipación',
                        ),
                      ),

                      user?.userMetadata?['taller'] !=
                                  "Taller de cerámica Ricardo Rojas" &&
                              !isWide
                          ? FutureBuilder<int>(
                              future: Future.delayed(Duration.zero, () {
                                return ObtenerClasesDisponibles()
                                    .clasesDisponibles(
                                  user?.userMetadata?['fullname'] ?? '',
                                );
                              }),
                              key: ValueKey(_recargaCreditos),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                final cantidad = snapshot.data!;
                                String texto = '';

                                if (cantidad > 1) {
                                  texto =
                                      '¡Tenés $cantidad créditos disponibles!';
                                } else if (cantidad == 1) {
                                  texto = '¡Tenés 1 crédito disponible!';
                                } else {
                                  texto = 'No tenés ningún crédito disponible';
                                }

                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: TituloSeleccion(texto: texto));
                              },
                            )
                          // const SizedBox(height: 30),
                          : SizedBox(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Divider(thickness: 2),
                      ),

                      // Show message if no classes and no waitlist, otherwise show the lists
                      (clasesDelUsuario.isEmpty &&
                              listaDeEsperaDelUsuario.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 30),
                                  const Icon(Icons.event_busy,
                                      size: 80, color: Colors.grey),
                                  const SizedBox(height: 20),
                                  Text(
                                    localizations
                                        .translate('noClassesEnrolled'),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w500,
                                      color: color.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    flex:
                                        listaDeEsperaDelUsuario.isEmpty ? 8 : 5,
                                    child: ListView.builder(
                                      itemCount: clasesDelUsuario.length,
                                      itemBuilder: (context, index) {
                                        final clase = clasesDelUsuario[index];
                                        final partesFecha =
                                            clase.fecha.split('/');
                                        final diaMes =
                                            '${partesFecha[0]}/${partesFecha[1]}';
                                        final diaMesAnio =
                                            '${clase.dia} $diaMes';
                                        final claseInfo =
                                            '$diaMesAnio - ${clase.hora}';

                                        final bool claseYaPaso = Calcular24hs()
                                            .esMenorA0Horas(clase.fecha,
                                                clase.hora, mesActual);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          child: Opacity(
                                            opacity: claseYaPaso ? 0.5 : 1.0,
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  claseInfo,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                                trailing: ElevatedButton(
                                                  onPressed: () {
                                                    mostrarCancelacion(
                                                        context, clase, false);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        const Color.fromARGB(
                                                            166, 252, 93, 93),
                                                  ),
                                                  child: Text(
                                                    localizations.translate(
                                                        'cancelButton'),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (listaDeEsperaDelUsuario.isNotEmpty)
                                    Expanded(
                                      flex: 3,
                                      child: ListView.builder(
                                        itemCount:
                                            listaDeEsperaDelUsuario.length,
                                        itemBuilder: (context, index) {
                                          final clase =
                                              listaDeEsperaDelUsuario[index];
                                          final partesFecha =
                                              clase.fecha.split('/');
                                          final diaMes =
                                              '${partesFecha[0]}/${partesFecha[1]}';
                                          final diaMesAnio =
                                              '${clase.dia} $diaMes';
                                          final claseInfo =
                                              '$diaMesAnio - ${clase.hora}';

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            child: Card(
                                              elevation: 4,
                                              color: const Color(0xFFE3F2FD),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ListTile(
                                                title: Text(
                                                  claseInfo,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  localizations.translate(
                                                      'waitlistPosition',
                                                      params: {
                                                        'position': (clase
                                                                    .espera
                                                                    .indexOf(user
                                                                            .userMetadata?[
                                                                        'fullname']) +
                                                                1)
                                                            .toString()
                                                      }),
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                trailing: ElevatedButton(
                                                  onPressed: () {
                                                    mostrarCancelacion(
                                                        context, clase, true);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF4FC3F7),
                                                  ),
                                                  child: Text(
                                                    localizations.translate(
                                                        'cancelButton'),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
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
                    ],
                  ),
          ),
        ),
        floatingActionButton: InformationButon(
            text:
                "1️⃣ Desde aquí podés ver todas las clases en las que estás anotado durante el mes.\n\n"
                "2️⃣ Si necesitás cancelar una clase, presioná el botón \"Cancelar\". Se abrirá una alerta para confirmar. Si cancelás con más de 24 hs de anticipación, vas a obtener un crédito para recuperar esa clase en otro momento. Si lo hacés con menos de 24 hs, no se genera crédito.\n\n"
                "3️⃣ También vas a ver tus clases en lista de espera. Si alguien cancela su lugar en una clase donde estás en espera, se te asignará automáticamente ese espacio y recibirás una notificación por WhatsApp."));
  }
}
