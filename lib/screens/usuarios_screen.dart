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
import 'package:taller_ceramica/widgets/crear_usuario_dialog.dart';
import 'package:taller_ceramica/widgets/information_buton.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key, String? taller});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool isLoading = true;
  List<UsuarioModels> usuarios = [];

  void mostrarAdvertenciaCrearUsuario(BuildContext context, String taller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advertencia'),
        content: const Text(
            'Antes de crear un usuario debes crear por lo menos una clase.'),
        actions: [
          FilledButton(
            onPressed: () {
              context.pop(); // Cierra el cartel
              context
                  .push('/gestionclases/$taller'); // Navega a gestión de clases
            },
            child: const Text('Gestión de clases'),
          ),
        ],
      ),
    );
  }

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

  Future<void> eliminarUsuario(String userUid) async {
    await EliminarUsuario().eliminarDeBaseDatos(userUid);
    await EliminarUsuario().eliminarUsuarioAutenticado(userUid);
    await EliminarUsuario().eliminarDeBaseDatos(userUid);
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
    final usuarioActivo = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar:
          ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
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
                                    surfaceTintColor: usuario.admin
                                        ? Colors.amber
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
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
                                              titulo:
                                                  AppLocalizations.of(context)
                                                      .translate('addCredits'),
                                              contenido:
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'selectCreditsToAdd'),
                                              onConfirmar: (cantidad) async {
                                                for (int i = 0;
                                                    i < cantidad;
                                                    i++) {
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
                                              titulo: AppLocalizations.of(
                                                      context)
                                                  .translate('removeCredits'),
                                              contenido: AppLocalizations.of(
                                                      context)
                                                  .translate(
                                                      'selectCreditsToRemove'),
                                              onConfirmar: (cantidad) async {
                                                for (int i = 0;
                                                    i < cantidad;
                                                    i++) {
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
                                    final clases = await AlumnosEnClase()
                                        .clasesAlumno(alumno, columna);
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          clases.isNotEmpty
                                              ? "Clases de $alumno:\n${clases.join('\n')}"
                                              : "$alumno no tiene clase asignadas.",
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        duration: const Duration(seconds: 7),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error al obtener las clases: $e",
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 7),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  final alumno = usuario.fullname;
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Row(
                                          children: [
                                            const FaIcon(
                                                FontAwesomeIcons
                                                    .triangleExclamation,
                                                size: 30),
                                            const SizedBox(width: 10),
                                            Flexible(
                                                child: Text(
                                              "¿Quieres eliminar a $alumno?",
                                            )),
                                          ],
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Cierra diálogo
                                            },
                                            child: const Text("Cancelar"),
                                          ),
                                          const SizedBox(width: 2),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade700,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              eliminarUsuario(
                                                usuario.userUid,
                                              );
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
          Positioned(
            bottom: 90, // Ajustado para no superponer el FloatingActionButton
            right: 20,
            child: InformationButon(text: '''
1️⃣ Para crear un nuevo alumno, presioná el botón "Crear nuevo usuario".
Se abrirá un formulario donde vas a ingresar el nombre, el correo, el teléfono y la contraseña.
El alumno usará su correo y contraseña para iniciar sesión.

2️⃣ En pantalla vas a ver el listado de tus alumnos.

3️⃣ A cada alumno podés:

➕ Sumarle créditos para que pueda anotarse en más clases.

➖ Quitarle créditos disponibles si es necesario.

4️⃣ Si tocás un alumno, vas a ver en qué clases está inscripto.

5️⃣ Si mantenés presionado sobre un alumno, vas a poder eliminarlo.
'''),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: size.width * 0.38,
        child: FloatingActionButton(
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return CrearUsuarioDialog(
                  onUsuarioCreado: () async {
                    await cargarUsuarios(); // refresca la lista
                  },
                );
              },
            );
          },
          child: Container(
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context).translate('createNewUser'),
              style: TextStyle(fontSize: size.width * 0.030),
            ),
          ),
        ),
      ),
    );
  }
}
