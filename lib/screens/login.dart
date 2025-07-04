import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assistify/supabase/utiles/redirijir_usuario_al_taller.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:assistify/utils/enviar_wpp.dart';
import 'package:assistify/widgets/contactanos.dart';
import 'package:assistify/widgets/titulo_seleccion.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  String passwordError = '';
  String mailError = '';
  bool hasFocusedEmailField = false;
  bool hasFocusedPasswordField = false;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    _checkSession();
    super.initState();

    // Escuchar cambios de foco en los campos
    emailFocusNode.addListener(() {
      if (emailFocusNode.hasFocus) {
        setState(() {
          hasFocusedEmailField = true;
        });
      }
    });

    passwordFocusNode.addListener(() {
      if (passwordFocusNode.hasFocus) {
        setState(() {
          hasFocusedPasswordField = true;
        });
      }
    });
  }

  void mostrarSnackBar(String mensaje) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _checkSession() async {
    // Recuperar la sesión desde SharedPreferences
    final user = Supabase.instance.client.auth.currentUser;

    // Si la sesión es válida, redirigir al usuario
    if (user != null) {
      await RedirigirUsuarioAlTaller().redirigirUsuario(context);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        toolbarHeight: kToolbarHeight * 1.1,
        title: GestureDetector(
          onTap: () {
            context.push("/subscription");
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.08),
                child: TituloAnimadoAssistify(
                  texto: '¡Bienvenidos a Assistify!',
                  size: size.width * 0.078,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TituloAnimadoAssistify(
                            texto: localizations.translate('loginPrompt'),
                            initialDelay: const Duration(milliseconds: 50 * 26),
                            size: size.width * 0.055,
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('emailLabel'),
                          border: const OutlineInputBorder(),
                          errorText: mailError.isEmpty ? null : mailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          setState(() {
                            mailError = !emailRegex
                                    .hasMatch(emailController.text.trim())
                                ? localizations.translate('invalidEmail')
                                : '';
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('passwordLabel'),
                          border: const OutlineInputBorder(),
                          errorText:
                              passwordError.isEmpty ? null : passwordError,
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            passwordError = value.length < 6
                                ? localizations.translate('passwordTooShort')
                                : '';
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () => context.go("/"),
                                child: Text(AppLocalizations.of(context)
                                    .translate('goBackButton'))),
                            const SizedBox(width: 15),
                            FilledButton(
                              onPressed: () async {
                                print('🔹 Botón de login presionado');
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                final connectivityResult =
                                    await Connectivity().checkConnectivity();
                                print(
                                    '🔍 Resultado de conexión: $connectivityResult');

                                if (connectivityResult ==
                                    ConnectivityResult.none) {
                                  print('⛔ Sin conexión a internet');
                                  mostrarSnackBar(
                                      'Verificá tu conexión a internet.');
                                  return;
                                }

// Validaciones de email y pass
                                if (!emailRegex.hasMatch(email)) {
                                  print('❌ Email inválido');
                                  mostrarSnackBar(
                                      localizations.translate('invalidEmail'));
                                  return;
                                }
                                if (password.length < 6) {
                                  print('❌ Contraseña muy corta');
                                  mostrarSnackBar(localizations
                                      .translate('passwordTooShort'));
                                  return;
                                }

// Login
                                try {
                                  print('🔐 Intentando login con Supabase');
                                  final response = await Supabase
                                      .instance.client.auth
                                      .signInWithPassword(
                                    email: email,
                                    password: password,
                                  );

                                  if (response.session != null) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final sessionData =
                                        response.session!.toJson();
                                    await prefs.setString(
                                        'session', jsonEncode(sessionData));
                                  }

                                  if (context.mounted) {
                                    final user = Supabase
                                        .instance.client.auth.currentUser;
                                    final metadata = user?.userMetadata ?? {};

                                    final tieneSexo = metadata['sexo'] != null;
                                    final tieneRubro =
                                        metadata['rubro'] != null;
                                    final tieneTaller =
                                        metadata['taller'] != null;
                                    final tieneTelefono =
                                        metadata['telefono'] != null;
                                    final tieneCreatedAt =
                                        metadata['created_at'] != null;

                                    if (!tieneSexo ||
                                        !tieneRubro ||
                                        !tieneTaller ||
                                        !tieneTelefono ||
                                        !tieneCreatedAt) {
                                      print(
                                          "✏️ Actualizando metadatos incompletos");

                                      await Supabase.instance.client.auth
                                          .updateUser(
                                        UserAttributes(data: {
                                          if (!tieneSexo) 'sexo': 'Mujer',
                                          if (!tieneRubro)
                                            'rubro': 'Clases de cerámica',
                                          if (!tieneTaller)
                                            'taller':
                                                'Taller de cerámica Ricardo Rojas',
                                          if (!tieneTelefono) 'telefono': null,
                                          if (!tieneCreatedAt)
                                            'created_at': DateTime.now()
                                                .toUtc()
                                                .toIso8601String(),
                                        }),
                                      );
                                    }

                                    RedirigirUsuarioAlTaller()
                                        .redirigirUsuario(context);
                                  }
                                } on AuthException catch (e) {
                                  print('🛑 AuthException: ${e.message}');
                                  final error = e.message.toLowerCase();

                                  if (error.contains("socketexception") ||
                                      error.contains("failed host lookup")) {
                                    mostrarSnackBar(
                                        "Verificá tu conexión a internet.");
                                  } else if (error.contains("user not found") ||
                                      error.contains(
                                          "invalid login credentials")) {
                                    mostrarSnackBar(
                                        "Verificá tu correo electrónico o contraseña.");
                                  } else if (error
                                      .contains("email not confirmed")) {
                                    mostrarSnackBar(
                                        "Confirmá tu correo electrónico antes de iniciar sesión.");
                                  } else if (error.contains("no user")) {
                                    mostrarSnackBar(
                                        "Pedile al administrador que registre tu cuenta.");
                                  } else {
                                    mostrarSnackBar(
                                        "Error al iniciar sesión. Intentá nuevamente.");
                                  }
                                }
                              },
                              child:
                                  Text(localizations.translate('loginButton')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TituloAnimadoAssistify extends StatefulWidget {
  final String texto;
  final TextStyle? estilo;
  final Duration initialDelay;
  final double size;

  const TituloAnimadoAssistify({
    super.key,
    required this.texto,
    this.estilo,
    this.initialDelay = Duration.zero,
    required this.size,
  });

  @override
  State<TituloAnimadoAssistify> createState() => _TituloAnimadoAssistifyState();
}

class _TituloAnimadoAssistifyState extends State<TituloAnimadoAssistify>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _offsetAnimations;
  late final List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(widget.texto.length, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      Future.delayed(widget.initialDelay + Duration(milliseconds: i * 50), () {
        if (mounted) controller.forward();
      });

      return controller;
    });

    _offsetAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Wrap(
      children: List.generate(widget.texto.length, (i) {
        final char = widget.texto[i];
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) {
            return Opacity(
              opacity: _opacityAnimations[i].value,
              child: Transform.translate(
                offset: _offsetAnimations[i].value * 20,
                child: Text(
                  char,
                  style: widget.estilo ??
                      TextStyle(
                        fontSize: widget.size,
                        fontFamily: 'Oxanium',
                        fontWeight: FontWeight.w900,
                        color: color.primary,
                      ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
