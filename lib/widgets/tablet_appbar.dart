import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart'; // Importación para traducción

class TabletAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const TabletAppBar({super.key})
      : preferredSize = const Size.fromHeight(kToolbarHeight * 2.2);

  @override
  TabletAppBarState createState() => TabletAppBarState();
}

class TabletAppBarState extends State<TabletAppBar> {
  bool _isMenuOpen = false;

  String? taller;
  bool isLoading = true;
  bool showLoader = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && isLoading) {
        setState(() {
          showLoader = true;
        });
      }
    });

    _cargarTaller();
  }

  Future<void> _cargarTaller() async {
    try {
      final usuarioActivo = Supabase.instance.client.auth.currentUser;
      if (usuarioActivo == null) {
        setState(() {
          errorMessage = AppLocalizations.of(context).translate('noActiveUser');
          isLoading = false;
          showLoader = false;
        });
        return;
      }

      final tallerObtenido =
          await ObtenerTaller().retornarTaller(usuarioActivo.id);

      setState(() {
        taller = tallerObtenido;
        isLoading = false;
        showLoader = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        showLoader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    if (isLoading && !showLoader) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: color.primary,
        title: Text(
          AppLocalizations.of(context).translate('loading'),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (isLoading && showLoader) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: color.primary,
        title: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        title: Text(
          '${AppLocalizations.of(context).translate('errorLabel')}: $errorMessage',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: Supabase.instance.client.auth.onAuthStateChange
          .map((event) => event.session?.user),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userId = user?.id;

        final adminRoutes = [
          {
            'value': '/turnos${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('classesLabel')
          },
          {
            'value': '/misclases${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('myClassesLabel')
          },
          {
            'value': '/gestionhorarios${taller ?? ''}',
            'label': AppLocalizations.of(context)
                .translate('manageSchedulesLabel')
          },
          {
            'value': '/gestionclases${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('manageClassesLabel')
          },
          {
            'value': '/usuarios${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('studentsLabel')
          },
          {
            'value': '/configuracion${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('settingsLabel')
          },
        ];

        final userRoutes = [
          {
            'value': '/turnos${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('classesLabel')
          },
          {
            'value': '/misclases${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('myClassesLabel')
          },
          {
            'value': '/configuracion${taller ?? ''}',
            'label': AppLocalizations.of(context).translate('settingsLabel')
          },
        ];

        final menuItems = (userId == "56f74db7-61ed-418f-a047-b94224a639ed" ||
                userId == "939d2e1a-13b3-4af0-be54-1a0205581f3b")
            ? adminRoutes
            : userRoutes;

        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: color.primary,
          toolbarHeight: widget.preferredSize.height,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push("/home${taller ?? ''}");
                },
                child: Row(
            children: [
              Text(
                AppLocalizations.of(context).translate('appTitle'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 7),
              FaIcon(FontAwesomeIcons.fileLines, color: Colors.white, size: size.width * 0.055,),
            ],
          ),
              ),
              SizedBox(width: size.width * 0.02),
              PopupMenuButton<String>(
                onSelected: (value) => context.push(value),
                itemBuilder: (BuildContext context) => menuItems
                    .map((route) => PopupMenuItem(
                          value: route['value'] as String,
                          child: Text(route['label'] as String),
                        ))
                    .toList(),
                icon: AnimatedRotation(
                  turns: _isMenuOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_outlined,
                    size: size.width * 0.02,
                    color: color.surface,
                  ),
                ),
                onOpened: () {
                  setState(() {
                    _isMenuOpen = true;
                  });
                },
                onCanceled: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                offset: Offset(-size.width * 0.03, size.height * 0.10),
              ),
              const Spacer(),
              user == null
                  ? SizedBox(
                      height: size.width * 0.03,
                      width: size.width * 0.15,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/iniciar-sesion${taller ?? ''}');
                        },
                        child: Text(
                          AppLocalizations.of(context).translate('loginLabel'),
                          style: TextStyle(fontSize: size.width * 0.015),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: size.width * 0.03,
                      width: size.width * 0.15,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('session');
                          if (context.mounted) {
                            context.push('/');
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context).translate('logoutLabel'),
                          style: TextStyle(fontSize: size.width * 0.015),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
