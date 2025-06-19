import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/is_admin.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  CustomAppBarState createState() => CustomAppBarState();
}

class CustomAppBarState extends State<CustomAppBar> {
  bool _isMenuOpen = false;

  String? taller;
  bool isLoading = true;
  bool showLoader = false;
  String? errorMessage;
  bool isAdmin = false;

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
    _checkAdminStatus();
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

  Future<void> _checkAdminStatus() async {
    try {
      final adminStatus = await IsAdmin().admin();
      setState(() {
        isAdmin = adminStatus;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            AppLocalizations.of(context).translate('adminCheckError');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    if (isLoading && !showLoader) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: color.primary,
        title: const SizedBox(),
      );
    }

    if (isLoading && showLoader) {
      return AppBar(
        backgroundColor: color.primary,
        title: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return AppBar(
        title: Text(
          '${AppLocalizations.of(context).translate('errorLabel')}: $errorMessage',
          style: TextStyle(
              color: color.onPrimary,
              fontSize: size.width * 0.05,
              fontFamily: 'Oxanium'),
        ),
        backgroundColor: color.primary,
      );
    }

    final user = Supabase.instance.client.auth.currentUser;

    final adminRoutes = [
      {
        'value': '/turnos/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('classesLabel'),
      },
      {
        'value': '/misclases/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('myClassesLabel'),
      },
      {
        'value': '/gestionhorarios/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('manageSchedulesLabel'),
      },
      {
        'value': '/gestionclases/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('manageClassesLabel'),
      },
      {
        'value': '/usuarios/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('studentsLabel'),
      },
      {
        'value': '/configuracion/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('settingsLabel'),
      },

      if (user?.userMetadata!["admin"])
        {
          'value': '/subscription',
          'label': "Suscribite",
        },
      // if (user?.id == '668da4f9-3487-42c5-8f28-fe2da23806d4')
      // {
      //   'value': '/prueba',
      //   'label': AppLocalizations.of(context).translate('testLabel'),
      // },
      if (user?.id == '55529ccc-07c0-4af4-958c-9267af58e39f')
        {
          'value': '/soporte',
          'label': "soporte",
        },
    ];

    final userRoutes = [
      {
        'value': '/turnos/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('classesLabel'),
      },
      {
        'value': '/misclases/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('myClassesLabel'),
      },
      {
        'value': '/configuracion/${taller ?? ''}',
        'label': AppLocalizations.of(context).translate('settingsLabel'),
      },
    ];

    final menuItems = (isAdmin) ? adminRoutes : userRoutes;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: color.primary,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              context.push("/home/${taller ?? ''}");
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Image.asset(
                'assets/icon/assistifyLogo.png', // ← asegurate que el path sea correcto
                height: isWide ? size.width * 0.27 : size.width * 0.42,
                fit: BoxFit.contain,
              ),
            ),
          ),
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
                color: color.surface,
                size: isWide ? size.width * 0.04 : size.width * 0.07,
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
            offset: Offset(isWide ? -size.width * 0.05 : -size.width * 0.05,
                isWide ? size.height * 0.3 : size.height * 0.07),
          ),
        ],
      ),
      actions: [
        user == null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size.width * 0.34,
                    height: size.height * 0.044,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/');
                      },
                      child: Text(
                        AppLocalizations.of(context).translate('loginLabel'),
                        style: TextStyle(fontSize: size.width * 0.034),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: size.width * 0.02),
                  SizedBox(
                    width: isWide ? size.width * 0.2 : size.width * 0.35,
                    height: isWide ? size.height * 0.1 : size.height * 0.044,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('session');

                        if (context.mounted) {
                          context.push('/');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero, // 🔽 Quita el padding interno
                        minimumSize: Size
                            .zero, // 🔽 Permite que se achique lo más posible
                        tapTargetSize: MaterialTapTargetSize
                            .shrinkWrap, // 🔽 Evita expansión automática por accesibilidad
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('logoutLabel'),
                        style: TextStyle(
                            fontSize: isWide
                                ? size.width * 0.015
                                : size.width * 0.035),
                      ),
                    ),
                  ),
                ],
              ),
        SizedBox(width: size.width * 0.032),
      ],
    );
  }
}
