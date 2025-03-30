// ignore_for_file: use_build_context_synchronously
// funciona
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';

class CambiarPassword extends StatefulWidget {
  const CambiarPassword({super.key});

  @override
  State<CambiarPassword> createState() => _CambiarPasswordState();
}

class _CambiarPasswordState extends State<CambiarPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String passwordError = '';
  String confirmPasswordError = '';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('changePasswordTitle'),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)
                        .translate('newPasswordLabel'),
                    border: const OutlineInputBorder(),
                    errorText: passwordError.isEmpty ? null : passwordError,
                  ),
                  obscureText: true,
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)
                        .translate('confirmPasswordLabel'),
                    border: const OutlineInputBorder(),
                    errorText: confirmPasswordError.isEmpty
                        ? null
                        : confirmPasswordError,
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      confirmPasswordError = value != passwordController.text
                          ? AppLocalizations.of(context)
                              .translate('passwordMismatchError')
                          : '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final nuevaPassword = passwordController.text.trim();
                    final confirmarPassword =
                        confirmPasswordController.text.trim();

                    // Validaciones
                    if (nuevaPassword.isEmpty || confirmarPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)
                                .translate('allFieldsRequiredError'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (nuevaPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)
                                .translate('passwordLengthError'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (nuevaPassword != confirmarPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)
                                .translate('passwordMismatchError'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Actualizar contraseña en Supabase
                    try {
                      await Supabase.instance.client.auth
                          .updateUser(UserAttributes(password: nuevaPassword));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)
                                .translate('passwordUpdatedSuccess'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)
                                .translate('passwordUpdateError', params: {'error': e.toString()}),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('updatePasswordButton'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
