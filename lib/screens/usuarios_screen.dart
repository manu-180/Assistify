// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/subscription/subscription_verifier.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/usuario_models.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

import '../utils/utils_barril.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key, String? taller});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool isLoading = true;
  List<UsuarioModels> usuarios = [];

  Future<void> cargarUsuarios() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    setState(() {
      isLoading = true;
    });

    final datos = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerUsuarios();
    if (mounted) {
      setState(() {
        usuarios = List<UsuarioModels>.from(
          datos.where((usuario) => usuario.taller == taller),
        );
        usuarios.sort((a, b) => a.fullname.compareTo(b.fullname)); // Ordenar
        isLoading = false;
      });
    }
  }

  Future<void> eliminarUsuario(int userId, String userUid) async {
    await EliminarUsuario().eliminarDeBaseDatos(userId);
    await EliminarDeBD().deleteCurrentUser(userUid);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('userDeletedSuccess'))),
    );
    await cargarUsuarios();
  }

  Future<void> agregarCredito(String user) async {
    final resultado = await ModificarCredito().agregarCreditoUsuario(user);
    if (resultado) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('creditsAddedSuccess'))),
      );
      await cargarUsuarios();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('errorAddingCredits'))),
      );
    }
  }

  Future<void> removerCredito(String user) async {
    final resultado = await ModificarCredito().removerCreditoUsuario(user);
    if (resultado) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('creditsRemovedSuccess'))),
      );
      await cargarUsuarios();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('errorRemovingCredits'))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    SubscriptionVerifier.verificarAdminYSuscripcion(context);
    cargarUsuarios();
  }

  Future<void> mostrarDialogoEliminar({
    required BuildContext context,
    required String titulo,
    required String contenido,
    required VoidCallback onConfirmar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(contenido),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancelar
              child: Text(AppLocalizations.of(context).translate('no')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(AppLocalizations.of(context).translate('yes')),
            ),
          ],
        );
      },
    );

    if (resultado == true) {
      onConfirmar();
    }
  }

  Future<void> mostrarDialogoConContador({
    required BuildContext context,
    required String titulo,
    required String contenido,
    required Function(int cantidad) onConfirmar,
  }) async {
    int contador = 1;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(titulo),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(contenido),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.orange),
                        onPressed: () {
                          if (contador > 1) {
                            setState(() {
                              contador--;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$contador',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            contador++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child:
                      Text(AppLocalizations.of(context).translate('confirm')),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == true) {
      onConfirmar(contador);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar:
          ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: BoxText(
                        text: AppLocalizations.of(context)
                            .translate('usersSectionDescription'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final usuario = usuarios[index];
                          return GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: Card(
                                surfaceTintColor:
                                    usuario.admin ? Colors.amber : Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Text(usuario.fullname),
                                  subtitle: Text(
                                    usuario.clasesDisponibles == 1
                                        ? "${usuario.clasesDisponibles} ${AppLocalizations.of(context).translate('singleCredit')}"
                                        : "${usuario.clasesDisponibles} ${AppLocalizations.of(context).translate('multipleCredits')}",
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            color: Colors.green),
                                        onPressed: () =>
                                            mostrarDialogoConContador(
                                          context: context,
                                          titulo: AppLocalizations.of(context)
                                              .translate('addCredits'),
                                          contenido: AppLocalizations.of(context)
                                              .translate('selectCreditsToAdd'),
                                          onConfirmar: (cantidad) async {
                                            for (int i = 0; i < cantidad; i++) {
                                              await agregarCredito(
                                                  usuario.fullname);
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove,
                                            color: Colors.orange),
                                        onPressed: () =>
                                            mostrarDialogoConContador(
                                          context: context,
                                          titulo: AppLocalizations.of(context)
                                              .translate('removeCredits'),
                                          contenido: AppLocalizations.of(context)
                                              .translate('selectCreditsToRemove'),
                                          onConfirmar: (cantidad) async {
                                            for (int i = 0; i < cantidad; i++) {
                                              await removerCredito(
                                                  usuario.fullname);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onTap: () async {
  final alumno = usuario.fullname; 
  const columna = 'mails'; 

  try {
    final clases = await AlumnosEnClase().clasesAlumno(alumno, columna);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clases.isNotEmpty
              ? "Clases de $alumno:\n${clases.join('\n')}" 
              : "No se encontraron clases para este alumno.",
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 7),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Error al obtener las clases: $e",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red, // Cambia el color si quieres
        duration: const Duration(seconds: 7),
      ),
    );
  }
} ,
onLongPress: () {
  final alumno = usuario.fullname; 
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation, size: 30,),
            SizedBox(width: 10),
            Flexible(
            child: Text(
              "¿Quieres eliminar a $alumno?",
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text("Cancelar"),
          ),
          SizedBox(
            width: 2,
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700, // Rojo oscuro
            ),
            onPressed: () {
              // Agregar lógica para eliminar al alumno
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text("Eliminar"),
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
                ),
              ),
            ),
      floatingActionButton: SizedBox(
  width: size.width * 0.38,
  child: FloatingActionButton(
    onPressed: () async {
      final usuarioActivo = Supabase.instance.client.auth.currentUser;
      final taller =
          await ObtenerTaller().retornarTaller(usuarioActivo!.id);
      context.push('/crear-usuario/$taller');
    },
    child: Container(
      alignment: Alignment.center, 
      child: Text(
        AppLocalizations.of(context).translate('createNewUser'),
        style: TextStyle(fontSize: size.width * 0.030),
      ),
    ),
  ),)
);
  }
}
