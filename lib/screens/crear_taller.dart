// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/utils_barril.dart';
import 'package:taller_ceramica/widgets/titulo_seleccion.dart';
import 'package:url_launcher/url_launcher.dart';

class CrearTallerScreen extends StatefulWidget {
  const CrearTallerScreen({super.key});

  @override
  State<CrearTallerScreen> createState() => _CrearTallerScreenState();
}

class _CrearTallerScreenState extends State<CrearTallerScreen> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController tallerController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String? sexoSeleccionado;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final RegExp phoneRegex = RegExp(r'^\+?[0-9]{7,15}\$');

  final List<String> rubros = [
    "Clases de cerámica",
    "Clases de pintura",
    "Clases de música",
    "Clases de idiomas",
    "Clases de danza",
    "Clases de actuación",
    "Clases de cocina",
    "Clases de tenis",
    "Clases de natación",
    "Entrenamientos de CrossFit",
    "Clases de artes marciales",
    "Clases de pilates",
    "Clases de gimnasia artística",
    "Clases de boxeo",
    "Clases de surf",
    "Clases de entrenamiento funcional",
    "Clases de yoga",
    "Clases de apoyo escolar",
    "Clases de adiestramiento para perros",
    "Clases de marketing digital",
    "Clases de fotografía comercial",
  ];

  String passwordError = '';
  String confirmPasswordError = '';
  String mailError = '';
  String phoneError = '';
  String tallerError = '';
  String? selectedRubro;
  bool isLoading = false;
  String fullnameError = '';
  bool aceptoPolitica = false;
  bool aceptaPoliticas = false;

  Future<void> crearTablaTaller(String taller) async {
    final int mesActual = DateTime.now().month;

    await supabase.rpc('create_table', params: {
      'query': '''
        CREATE TABLE IF NOT EXISTS "$taller" (
          id SERIAL PRIMARY KEY,
          semana TEXT NOT NULL,
          dia TEXT NOT NULL,
          fecha TEXT NOT NULL,
          hora TEXT NOT NULL,
          feriado BOOLEAN NOT NULL DEFAULT FALSE,
          mails JSONB DEFAULT '[]',
          lugar_disponible INTEGER NOT NULL DEFAULT 0,
          mes INTEGER NOT NULL DEFAULT $mesActual,
          espera JSONB DEFAULT '[]'
        );
      '''
    });
  }

  Future<bool> emailYaRegistrado(String email) async {
    final res = await supabase
        .from('usuarios')
        .select('usuario')
        .eq('usuario', email)
        .limit(1)
        .maybeSingle();

    return res != null;
  }

  Future<bool> tallerYaExiste(String nombre) async {
    final res = await supabase
        .from('usuarios')
        .select('taller')
        .ilike('taller', nombre.trim()); // insensitive LIKE

    return res.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: kToolbarHeight * 1.1,
        title: GestureDetector(
          onTap: () {
            context.push("/");
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Image.asset(
              'assets/icon/assistifyLogo.png', // ← asegurate que el path sea correcto
              height: size.width * 0.42,
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: color.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      TituloSeleccion(
                        texto: AppLocalizations.of(context)
                            .translate('createWorkshopIntro'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)
                                    .translate('infoTitle')),
                                content: SingleChildScrollView(
                                  child: Text(AppLocalizations.of(context)
                                      .translate('infoContent')),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(AppLocalizations.of(context)
                                        .translate('closeButton')),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon:
                            const Icon(Icons.info_outline), // Icono en el botón
                        label: Text(AppLocalizations.of(context)
                            .translate('moreInfoButton')),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: fullnameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('fullNameLabel'),
                          border: const OutlineInputBorder(),
                          errorText:
                              fullnameError.isEmpty ? null : fullnameError,
                        ),
                        keyboardType: TextInputType.name,
                        onChanged: (value) async {
                          final nombre = value.trim();
                          if (nombre.isEmpty) {
                            setState(() => fullnameError = "");
                            return;
                          }

                          final existe = await supabase
                              .from('usuarios')
                              .select('fullname')
                              .ilike('fullname', nombre)
                              .limit(1)
                              .maybeSingle();

                          setState(() {
                            fullnameError = existe != null
                                ? "Ese nombre ya está registrado."
                                : "";
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tallerController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('workshopNameLabel'),
                          border: const OutlineInputBorder(),
                          errorText: tallerError.isEmpty ? null : tallerError,
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) async {
                          final simbolosInvalidos =
                              RegExp(r'[^\w\sáéíóúÁÉÍÓÚñÑ]');
                          final nombre = value.trim();

                          if (nombre.isEmpty) {
                            setState(() {
                              tallerError = AppLocalizations.of(context)
                                  .translate('emptyWorkshopNameError');
                            });
                            return;
                          }

                          if (simbolosInvalidos.hasMatch(nombre)) {
                            setState(() {
                              tallerError =
                                  "No se aceptan símbolos. Contactá a soporte si es necesario.";
                            });
                            return;
                          }

                          final existe = await tallerYaExiste(nombre);

                          setState(() {
                            tallerError = existe
                                ? "Ya existe ese nombre de empresa."
                                : '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('emailLabel'),
                          border: const OutlineInputBorder(),
                          errorText: mailError.isEmpty ? null : mailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) async {
                          final emailActual = value.trim();
                          final emailRegex = RegExp(
                            r"^[\wñÑáéíóúÁÉÍÓÚ.!#$%&'*+/=?^_`{|}~-]+@"
                            r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
                            r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
                          );

                          if (!emailRegex.hasMatch(emailActual)) {
                            setState(() {
                              mailError = AppLocalizations.of(context)
                                  .translate('invalidEmailError');
                            });
                            return;
                          }

                          final existe = await emailYaRegistrado(emailActual);

                          // solo mostrar el error si el valor no cambió durante el await
                          if (emailActual == emailController.text.trim()) {
                            setState(() {
                              mailError = existe
                                  ? 'Este correo electrónico ya está registrado.'
                                  : '';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: "Teléfono",
                          border: const OutlineInputBorder(),
                          errorText: phoneError.isEmpty ? null : phoneError,
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) async {
                          final phone = value.trim();
                          final regex = RegExp(r'^[0-9]{7,15}$');

                          if (!regex.hasMatch(phone)) {
                            setState(() => phoneError =
                                "Número inválido. (ej: 1134272488)");
                            return;
                          }

                          final existe = await supabase
                              .from('usuarios')
                              .select('telefono')
                              .eq('telefono', phone)
                              .limit(1)
                              .maybeSingle();

                          setState(() {
                            phoneError = existe != null
                                ? "Ese número ya está registrado."
                                : "";
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
  children: ['Hombre', 'Mujer', 'Indefinido']
      .asMap()
      .entries
      .map((entry) {
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
          margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
          decoration: BoxDecoration(
            color: esSeleccionado
                ? color.primary.withOpacity(0.1)
                : color.background,
            border: Border.all(
              color:
                  esSeleccionado ? color.primary : Colors.black54,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                esSeleccionado
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  opcion,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: esSeleccionado
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: esSeleccionado
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }).toList(),
),
const SizedBox(height: 4),
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Sexo (opcional)",
    style: TextStyle(
      fontSize: 12,
      color: Colors.black54,
      fontStyle: FontStyle.italic,
    ),
  ),
),

                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Seleccione su rubro",
                          border: const OutlineInputBorder(),
                        ),
                        value: selectedRubro,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRubro = newValue;
                          });
                        },
                        items: rubros
                            .map((rubro) => DropdownMenuItem(
                                value: rubro, child: Text(rubro)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('passwordLabel'),
                          border: const OutlineInputBorder(),
                          errorText:
                              passwordError.isEmpty ? null : passwordError,
                        ),
                        onChanged: (value) {
                          setState(() {
                            passwordError = value.length < 6
                                ? AppLocalizations.of(context)
                                    .translate('passwordLengthError')
                                : '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('confirmPasswordLabel'),
                          border: const OutlineInputBorder(),
                          errorText: confirmPasswordError.isEmpty
                              ? null
                              : confirmPasswordError,
                        ),
                        onChanged: (value) {
                          setState(() {
                            confirmPasswordError =
                                value != passwordController.text
                                    ? AppLocalizations.of(context)
                                        .translate('passwordMismatchError')
                                    : '';
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Checkbox(
      value: aceptaPoliticas,
      onChanged: (value) {
        setState(() {
          aceptaPoliticas = value ?? false;
        });
      },
    ),
    Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            aceptaPoliticas = !aceptaPoliticas;
          });
        },
        child: Wrap(
          children: [
            const Text("Al continuar, aceptás nuestra "),
            InkWell(
              onTap: () async {
                const url = 'https://politicas-six.vercel.app/';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Política de Privacidad",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color.fromARGB(255, 61, 132, 191),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(" y los "),
            InkWell(
              onTap: () async {
                const url =
                    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Términos de uso",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color.fromARGB(255, 61, 132, 191),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text("."),
          ],
        ),
      ),
    ),
  ],
),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go("/"),
                            child: Text(AppLocalizations.of(context)
                                .translate('goBackButton')),
                          ),
                          const SizedBox(width: 15),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    FocusScope.of(context).unfocus();
                                    final fullname =
                                        fullnameController.text.trim();
                                    final email = emailController.text.trim();
                                    final taller = tallerController.text.trim();
                                    final telefono =
                                        phoneController.text.trim();
                                    final password =
                                        passwordController.text.trim();
                                    final confirmPassword =
                                        confirmPasswordController.text.trim();

                                    // Validaciones iniciales
                                    final existeTaller =
                                        await tallerYaExiste(taller);
                                    final existeMail =
                                        await emailYaRegistrado(email);
                                    final existeNombre = await supabase
                                            .from('usuarios')
                                            .select('fullname')
                                            .ilike('fullname', fullname)
                                            .limit(1)
                                            .maybeSingle() !=
                                        null;
                                    final existeTelefono = await supabase
                                            .from('usuarios')
                                            .select('telefono')
                                            .eq('telefono', telefono)
                                            .limit(1)
                                            .maybeSingle() !=
                                        null;

                                    if (existeNombre) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "El nombre ya está registrado"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (existeMail) {
                                      setState(() {
                                        mailError =
                                            'Este correo electrónico ya está registrado.';
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Este correo electrónico ya está registrado."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (existeTaller) {
                                      setState(() {
                                        tallerError =
                                            "Ya existe ese nombre de empresa.";
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "El nombre de empresa ya existe."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (existeTelefono) {
                                      setState(() {
                                        phoneError =
                                            "Ese número ya está registrado.";
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Ese número ya está registrado."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (fullname.isEmpty ||
                                        email.isEmpty ||
                                        taller.isEmpty ||
                                        telefono.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .translate(
                                                    'allFieldsRequiredError'),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (password.length < 6) {
                                      setState(() {
                                        passwordError = AppLocalizations.of(
                                                context)
                                            .translate('passwordLengthError');
                                        isLoading = false;
                                      });
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      setState(() {
                                        confirmPasswordError =
                                            AppLocalizations.of(context)
                                                .translate(
                                                    'passwordMismatchError');
                                        isLoading = false;
                                      });
                                      return;
                                    }

                                    if (email.contains('ñ') ||
                                        email.contains('Ñ')) {
                                      setState(() {
                                        mailError =
                                            "Los correos electrónicos no pueden contener la letra 'ñ'.";
                                        isLoading = false;
                                      });
                                      return;
                                    }
                                    if (!aceptaPoliticas) {
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Debés aceptar la Política de Privacidad para continuar."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Si pasó todas las validaciones, continúa con el registro
                                    try {
                                      final AuthResponse res =
                                          await supabase.auth.signUp(
                                        email: email,
                                        password: password,
                                        data: {
                                          'fullname':
                                              Capitalize().capitalize(fullname),
                                          "rubro": selectedRubro,
                                          "taller":
                                              Capitalize().capitalize(taller),
                                          "telefono": telefono,
                                          "sexo": sexoSeleccionado,
                                          "admin": true,
                                          "created_at":
                                              DateTime.now().toIso8601String(),
                                        },
                                      );

                                      if (res.user != null) {
                                        print(
                                            "✅ Usuario creado correctamente.");
                                      } else {
                                        print("❌ No se creó el usuario.");
                                      }

                                      await supabase.from('usuarios').insert({
                                        'id': await GenerarId()
                                            .generarIdUsuario(),
                                        'usuario': email,
                                        'fullname':
                                            Capitalize().capitalize(fullname),
                                        'user_uid': res.user?.id,
                                        "sexo": sexoSeleccionado,
                                        'clases_disponibles': 0,
                                        'trigger_alert': 0,
                                        'clases_canceladas': [],
                                        'taller':
                                            Capitalize().capitalize(taller),
                                        "admin": true,
                                        "created_at":
                                            DateTime.now().toIso8601String(),
                                        "rubro": selectedRubro,
                                        "telefono": telefono,
                                      });

                                      await crearTablaTaller(
                                          Capitalize().capitalize(taller));

                                      EnviarWpp().sendWhatsAppMessage(
                                          "HXa9fb3930150f932869bc13f223f26628",
                                          'whatsapp:+549$telefono',
                                          [fullname, "", "", "", ""]);

                                      if (context.mounted) {
                                        context.go("/");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .translate(
                                                    'workshopCreatedSuccess'),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.green,
                                        ));
                                      }
                                    } catch (e) {
                                      final error = e.toString().toLowerCase();
                                      String mensajeError;

                                      if (error.contains(
                                          "user already registered")) {
                                        mensajeError =
                                            "Este correo ya está registrado.";
                                      } else if (error
                                              .contains("invalid format") ||
                                          error.contains("validation_failed")) {
                                        mensajeError =
                                            "El correo electrónico ingresado no es válido. Verificá que esté bien escrito.";
                                      } else {
                                        mensajeError =
                                            "Hubo un error al crear la cuenta. Intentá nuevamente.";
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            mensajeError,
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white))
                                : Text(AppLocalizations.of(context)
                                    .translate('registerWorkshopButton')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
