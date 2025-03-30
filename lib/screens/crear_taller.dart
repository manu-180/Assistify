import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/utils_barril.dart';

class CrearTallerScreen extends StatefulWidget {
  const CrearTallerScreen({super.key});

  @override
  State<CrearTallerScreen> createState() => _CrearTallerScreenState();
}

class _CrearTallerScreenState extends State<CrearTallerScreen> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController tallerController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

   

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
  String tallerError = '';
  String? selectedRubro;
  bool isLoading = false;

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
      mails JSONB DEFAULT '[]',
      lugar_disponible INTEGER NOT NULL DEFAULT 0,
      mes INTEGER NOT NULL DEFAULT $mesActual,
      capacidad INTEGER NOT NULL DEFAULT 0,
      espera JSONB DEFAULT '[]'
      
    );
  '''
    });
  }

  

  @override
  Widget build(BuildContext context) {

    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

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
        child: Column(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(size.width * 0.05),
                  child: BoxText(
                      text: AppLocalizations.of(context)
                          .translate('createWorkshopIntro')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                              AppLocalizations.of(context).translate('infoTitle')),
                          content: SingleChildScrollView(
                            child: Text(
                                AppLocalizations.of(context).translate('infoContent')),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                  AppLocalizations.of(context).translate('closeButton')),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.info_outline), // Icono en el botón
                  label: Text(AppLocalizations.of(context).translate('moreInfoButton')),
                ),
                SizedBox(
                  height: size.width * 0.05,
                )
              ],
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextField(
                          controller: fullnameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)
                                .translate('fullNameLabel'),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.name,
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
                          onChanged: (value) {
                            setState(() {
                              mailError = !emailRegex
                                      .hasMatch(emailController.text.trim())
                                  ? AppLocalizations.of(context)
                                      .translate('invalidEmailError')
                                  : '';
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
                          onChanged: (value) {
                            setState(() {
                              tallerError = tallerController.text.trim().isEmpty
                                  ? AppLocalizations.of(context)
                                      .translate('emptyWorkshopNameError')
                                  : '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: "Seleccione su rubro",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0), // Bordes redondeados
      borderSide: const BorderSide(
        color: Colors.black, // Color del marco
        width: 1.0, // Grosor del marco
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0), // Bordes redondeados
      borderSide: const BorderSide(
        color: Colors.black, // Color del marco cuando no está seleccionado
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0), // Bordes redondeados
      borderSide:  BorderSide(
        color: color.primary, // Color del marco cuando está enfocado
        width: 1.5,
      ),
    ),
  ),
  value: selectedRubro,
  onChanged: (String? newValue) {
    setState(() {
      selectedRubro = newValue;
    });
  },
  items: rubros.map<DropdownMenuItem<String>>((String rubro) {
    return DropdownMenuItem<String>(
      value: rubro,
      child: Text(rubro),
    );
  }).toList(),
),
const SizedBox(height: 16),

      
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)
                                .translate('passwordLabel'),
                            border: const OutlineInputBorder(),
                            errorText:
                                passwordError.isEmpty ? null : passwordError,
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
                              confirmPasswordError =
                                  value != passwordController.text
                                      ? AppLocalizations.of(context)
                                          .translate('passwordMismatchError')
                                      : '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () => context.go("/"),
                                child: Text(AppLocalizations.of(context)
                                    .translate('goBackButton'))),
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
                                      final taller =
                                          tallerController.text.trim();
                                      final password =
                                          passwordController.text.trim();
                                      final confirmPassword =
                                          confirmPasswordController.text.trim();

                                      if (fullname.isEmpty ||
                                          email.isEmpty ||
                                          taller.isEmpty ||
                                          password.isEmpty ||
                                          confirmPassword.isEmpty) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .translate('allFieldsRequiredError'),
                                            style:
                                                const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ));
                                        return;
                                      }

                                      if (password.length < 6) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .translate('passwordLengthError'),
                                            style:
                                                const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ));
                                        return;
                                      }

                                      if (password != confirmPassword) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)
                                                .translate('passwordMismatchError'),
                                            style:
                                                const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ));
                                        return;
                                      }

                                      try {
                                        final AuthResponse res =
                                            await supabase.auth.signUp(
                                          email: email,
                                          password: password,
                                          data: {
                                            'fullname': Capitalize()
                                                .capitalize(fullname)
                                          },
                                        );

                                      

                                        await supabase.from('usuarios').insert({
                                          'id': await GenerarId()
                                              .generarIdUsuario(),
                                          'usuario': email,
                                          'fullname':
                                              Capitalize().capitalize(fullname),
                                          'user_uid': res.user?.id,
                                          'sexo': "mujer",
                                          'clases_disponibles': 0,
                                          'trigger_alert': 0,
                                          'clases_canceladas': [],
                                          'taller':
                                              Capitalize().capitalize(taller),
                                          "admin": true,
                                          "created_at":
                                              DateTime.now().toIso8601String(),
                                              "rubro": selectedRubro,
                                        });

                                        crearTablaTaller(
                                            Capitalize().capitalize(taller));

                                        EnviarWpp().sendWhatsAppMessage("HXce5db05ee13a1c05f412591b9747ff41", 'whatsapp:+5491134272488', [fullname, "", "", "", ""]);
                                        if (context.mounted) {
                                          context.go("/");
                                        }

                                        setState(() {
                                          isLoading = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)
                                                  .translate('workshopCreatedSuccess'),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: Colors.green,
                                          ));
                                        }
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)
                                                  .translate('workshopCreationError',
                                                      params: {'error': e.toString()}),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      }
                                    },
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(AppLocalizations.of(context)
                                      .translate('registerWorkshopButton')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


