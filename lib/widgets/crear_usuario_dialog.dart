import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_rubro.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/capitalize.dart';
import 'package:taller_ceramica/utils/crear_usuario_desde_admin.dart';

class CrearUsuarioDialog extends StatefulWidget {
  final Future<void> Function()? onUsuarioCreado;

  const CrearUsuarioDialog({Key? key, this.onUsuarioCreado}) : super(key: key);

  @override
  _CrearUsuarioDialogState createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<CrearUsuarioDialog> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  final TextEditingController phoneController = TextEditingController();

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp phoneRegex = RegExp(r'^\+?\d{7,15}$');

  String emailError = '';
  String passwordError = '';
  String phoneError = '';
  String fullnameError = '';
  String? sexoSeleccionado;
  String confirmarPassword = '';

  Future<void> validarNombre(String nombre) async {
    final existingUsers = await supabase
        .from('usuarios')
        .select('fullname')
        .ilike('fullname', nombre.trim());

    setState(() {
      fullnameError =
          existingUsers.isNotEmpty ? 'Ese nombre ya esta registrado.' : '';
    });
  }

  Future<bool> telefonoYaRegistrado(String telefono) async {
    final res = await supabase
        .from('usuarios')
        .select('telefono')
        .eq('telefono', telefono.trim())
        .maybeSingle();

    return res != null;
  }

  Future<bool> emailYaRegistrado(String email) async {
    final res = await supabase
        .from('usuarios')
        .select('usuario')
        .eq('usuario', email.trim())
        .limit(1)
        .maybeSingle();

    return res != null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: BounceInDown(
              duration: const Duration(milliseconds: 800),
              child: InkWell(
                onTap: () async {
                  final usuarioActivo =
                      Supabase.instance.client.auth.currentUser;
                  final taller =
                      await ObtenerTaller().retornarTaller(usuarioActivo!.id);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: color.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Información",
                              style: TextStyle(color: color.primary),
                            ),
                          ],
                        ),
                        content: Text(
                          "Aquí debes crear la cuenta de tus alumnos. "
                          "Es importante hacerlo de esta manera para que, al iniciar sesión, "
                          "ellos sean reconocidos por el programa y redirigidos automáticamente "
                          "al grupo de usuarios que corresponde a $taller.",
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Entendido"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
                hoverColor: Theme.of(context).primaryColor.withOpacity(0.1),
                mouseCursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "Crear un nuevo usuario",
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: fullnameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                border: const OutlineInputBorder(),
                errorText: fullnameError.isEmpty ? null : fullnameError,
              ),
              keyboardType: TextInputType.name,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  validarNombre(value);
                } else {
                  setState(() {
                    fullnameError = '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                border: const OutlineInputBorder(),
                errorText: emailError.isEmpty ? null : emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) async {
                final emailActual = value.trim();

                if (!emailRegex.hasMatch(emailActual)) {
                  setState(() {
                    emailError = 'Correo electrónico inválido';
                  });
                  return;
                }

                final existe = await emailYaRegistrado(emailActual);

                if (emailActual == emailController.text.trim()) {
                  setState(() {
                    emailError = existe ? 'Ese mail ya fue registrado' : '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Selector de sexo
            Row(
              children: ['Hombre', 'Mujer'].asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                final esSeleccionado = sexoSeleccionado == opcion;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        sexoSeleccionado = opcion;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 1 ? 8 : 0,
                        right: index == 0 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: esSeleccionado
                            ? color.primary.withOpacity(0.1)
                            : const Color.fromARGB(255, 229, 233,
                                239), // Fondo suave gris-azulado moderno
                        border: Border.all(
                          color: esSeleccionado
                              ? color.primary
                              : const Color.fromARGB(255, 119, 119,
                                  120), // Gris claro para el borde no activo
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        // 6

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              esSeleccionado
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              opcion,
                              style: TextStyle(
                                fontWeight: esSeleccionado
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: esSeleccionado
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                border: const OutlineInputBorder(),
                errorText: phoneError.isEmpty ? null : phoneError,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) async {
                final numero = value.trim();
                if (!phoneRegex.hasMatch(numero)) {
                  setState(() {
                    phoneError = 'Teléfono inválido';
                  });
                  return;
                }

                final existe = await telefonoYaRegistrado(numero);

                if (numero == phoneController.text.trim()) {
                  setState(() {
                    phoneError = existe ? 'Ese número ya está registrado' : '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                errorText: passwordError.isEmpty ? null : passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                setState(() {
                  passwordError = value.length >= 6
                      ? ''
                      : 'La contraseña debe tener al menos 6 caracteres';
                });
              },
            ),
            const SizedBox(height: 16),

            // Confirmar contraseña
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  confirmarPassword = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () async {
            final fullname = fullnameController.text.trim();
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            final telefono = phoneController.text.trim();

            final yaExiste = await emailYaRegistrado(email);
            final nombreYaExiste = await supabase
                .from('usuarios')
                .select('fullname')
                .ilike('fullname', fullname)
                .limit(1)
                .maybeSingle();
            final telExiste = await telefonoYaRegistrado(telefono);

            if (sexoSeleccionado == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Seleccioná el sexo del usuario."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (password != confirmarPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Las contraseñas no coinciden."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (telExiste) {
              setState(() => phoneError = 'Ese número ya está registrado');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Ese número ya está registrado"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (nombreYaExiste != null) {
              setState(() => fullnameError = 'Ya existe este nombre');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Ese nombre ya fue registrado"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (yaExiste) {
              setState(() => emailError = 'Ese mail ya fue registrado');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Ese mail ya fue registrado"),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (fullname.isEmpty ||
                email.isEmpty ||
                password.isEmpty ||
                phoneController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Por favor, completá todos los campos."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (!emailRegex.hasMatch(email)) {
              setState(() => emailError = 'Correo electrónico inválido');
              return;
            } else {
              setState(() => emailError = '');
            }

            if (password.length < 6) {
              setState(() => passwordError =
                  'La contraseña debe tener al menos 6 caracteres');
              return;
            } else {
              setState(() => passwordError = '');
            }

            if (!phoneRegex.hasMatch(phoneController.text.trim())) {
              setState(() => phoneError = 'Teléfono inválido');
              return;
            } else {
              setState(() => phoneError = '');
            }

            final usuarioActivo = Supabase.instance.client.auth.currentUser;
            final taller =
                await ObtenerTaller().retornarTaller(usuarioActivo!.id);

            final existingUsers = await supabase
                .from('usuarios')
                .select('fullname')
                .eq('taller', taller)
                .ilike('fullname', fullname);

            if (existingUsers.isNotEmpty) {
              setState(() {
                fullnameError = 'Ya existe este nombre en tus usuarios';
              });
              return;
            } else {
              setState(() {
                fullnameError = '';
              });
            }

            try {
              final userId = await crearUsuarioAdmin(
                  email: email,
                  password: password,
                  fullname: fullname,
                  telefono: telefono,
                  rubro: usuarioActivo.userMetadata?['rubro'] ?? 'Sin rubro',
                  taller: usuarioActivo.userMetadata?['taller'] ?? 'Sin taller',
                  sexo: sexoSeleccionado);

              await supabase.from('usuarios').insert({
                'id': await GenerarId().generarIdUsuario(),
                'usuario': email,
                'fullname': Capitalize().capitalize(fullname),
                'user_uid': userId,
                'sexo': sexoSeleccionado, // 👈 esto es nuevo
                'clases_disponibles': 0,
                'trigger_alert': 0,
                'clases_canceladas': [],
                'taller': taller,
                'telefono': telefono,
                'rubro': await ObtenerRubro()
                    .rubro(usuarioActivo.userMetadata?['fullname']),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "La cuenta de $fullname se creó exitosamente. ¡Ya puede iniciar sesión!.",
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 9),
                ),
              );

              final callback = widget.onUsuarioCreado;
              Navigator.of(context).pop();

              if (callback != null) {
                Future.microtask(() async {
                  await callback();
                });
              }
            } on AuthException catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Ese mail ya fue registrado"),
                  backgroundColor: Colors.red,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Contactá a soporte. Ocurrió un error inesperado: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text("Crear Usuario"),
        ),
      ],
    );
  }
}
