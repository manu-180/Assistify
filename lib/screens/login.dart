import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/utiles/redirijir_usuario_al_taller.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'dart:convert';

import 'package:taller_ceramica/widgets/contactanos.dart';

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
    child: Row(
      children: [
        Text(
          AppLocalizations.of(context).translate('appTitle'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 7),
        FaIcon(
          FontAwesomeIcons.fileLines,
          color: Colors.white,
          size: size.width * 0.055,
        ),
      ],
    ),
    onTap: () => context.go('/'),
  ),
  backgroundColor: color.primary,
),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(size.width * 0.04, size.width * 0.08,size.width * 0.04,0),
                child: Text(
                  localizations.translate('homeScreenIntro'),
                  style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                          ),
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
                          Text(
                            localizations.translate('loginPrompt'),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                            textAlign: TextAlign.center,
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
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                if (!emailRegex.hasMatch(email)) {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations
                                          .translate('invalidEmail')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (password.length < 6) {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations
                                          .translate('passwordTooShort')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  // Iniciar sesión
                                  final response = await Supabase
                                      .instance.client.auth
                                      .signInWithPassword(
                                    email: email,
                                    password: password,
                                  );

                                  // Guardar sesión manualmente (SharedPreferences)
                                  if (response.session != null) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final sessionData =
                                        response.session!.toJson();

                                    await prefs.setString(
                                        'session', jsonEncode(sessionData));
                                  }
                                  if (context.mounted) {
                                    RedirigirUsuarioAlTaller()
                                        .redirigirUsuario(context);
                                  }
                                  return;
                                } on AuthException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('loginError', params: {
                                          'error': e.message 
                                        })),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('unexpectedError')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
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
      floatingActionButton: Contactanos(),
    );
  }
}
