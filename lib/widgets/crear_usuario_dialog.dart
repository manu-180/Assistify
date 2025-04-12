import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/capitalize.dart';

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

  Future<void> validarNombre(String nombre) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final existingUsers = await supabase
        .from('usuarios')
        .select('fullname')
        .eq('taller', taller)
        .ilike('fullname', nombre.trim());

    setState(() {
      fullnameError = existingUsers.isNotEmpty
          ? 'Ya existe este nombre en tus usuarios'
          : '';
    });
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
              onChanged: (value) {
                setState(() {
                  emailError = emailRegex.hasMatch(value.trim())
                      ? ''
                      : 'Correo electrónico inválido';
                });
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
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                border: const OutlineInputBorder(),
                errorText: phoneError.isEmpty ? null : phoneError,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  phoneError = phoneRegex.hasMatch(value.trim())
                      ? ''
                      : 'Teléfono inválido. ';
                });
              },
            ),
            const SizedBox(height: 16),
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

// Validar si el nombre ya existe en este taller
            final existingUsers = await supabase
                .from('usuarios')
                .select('fullname')
                .eq('taller', taller)
                .ilike(
                    'fullname', fullname); // búsqueda insensible a mayúsculas

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
              setState(() {});

              final usuarioActivo = Supabase.instance.client.auth.currentUser;
              final taller =
                  await ObtenerTaller().retornarTaller(usuarioActivo!.id);

              final res = await supabase.auth.signUp(
                email: email,
                password: password,
                data: {
                  'fullname': Capitalize().capitalize(fullname),
                },
              );

              await supabase.from('usuarios').insert({
                'id': await GenerarId().generarIdUsuario(),
                'usuario': email,
                'fullname': Capitalize().capitalize(fullname),
                'user_uid': res.user?.id,
                'sexo': "mujer",
                'clases_disponibles': 0,
                'trigger_alert': 0,
                'clases_canceladas': [],
                'taller': taller,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "La cuenta de $fullname se creó exitosamente. Se envió un link de confirmación a $email.",
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 9),
                ),
              );

              Navigator.of(context).pop();
              if (widget.onUsuarioCreado != null) {
                await widget.onUsuarioCreado!();
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
