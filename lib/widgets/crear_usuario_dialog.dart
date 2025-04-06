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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final usuarioActivo = Supabase.instance.client.auth.currentUser;
              final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text("Información"),
                    ],
                  ),
                  content: Text(
                    "En esta pantalla podés crear usuarios para tus alumnos. "
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
            },
            child: const Icon(Icons.info_outline),
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
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
              keyboardType: TextInputType.text,
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

  if (fullname.isEmpty || email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Por favor, completá todos los campos."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    setState(() {});

    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

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
        content: Text("Error al registrar: ${e.message}"),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ocurrió un error inesperado: $e"),
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
