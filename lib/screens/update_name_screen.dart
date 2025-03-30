// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/supabase/usuarios/update_user.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/utils/capitalize.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

class UpdateNameScreen extends StatefulWidget {
  const UpdateNameScreen({super.key, String? taller});

  @override
  UpdateNameScreenState createState() => UpdateNameScreenState();
}

class UpdateNameScreenState extends State<UpdateNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _updateName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final taller = await ObtenerTaller().retornarTaller(user!.id);
      final listausuarios = await ObtenerTotalInfo(
        supabase: supabase,
        usuariosTable: 'usuarios',
        clasesTable: taller,
      ).obtenerUsuarios();
      final fullnameExiste = listausuarios.any((usuario) =>
          usuario.fullname.toLowerCase() ==
          _fullnameController.text.toLowerCase());

      if (fullnameExiste) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context).translate('nameAlreadyExists')),
            ),
          );
        }
        throw AppLocalizations.of(context).translate('nameAlreadyExists');
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'fullname': Capitalize().capitalize(_fullnameController.text)},
        ),
      );

      await UpdateUser(supabase).updateUser(
        user.userMetadata?['fullname'] ?? '',
        Capitalize().capitalize(_fullnameController.text),
      );

      await UpdateUser(supabase).updateTableUser(
        user.id,
        Capitalize().capitalize(_fullnameController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('nameUpdatedSuccess')),
          ),
        );
        _fullnameController.clear();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar:
          ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).translate('enterNewName'),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText:
                      AppLocalizations.of(context).translate('fullNameLabel'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)
                        .translate('validNameError');
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateName,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context)
                          .translate('updateNameButton')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
