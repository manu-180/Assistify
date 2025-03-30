import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/screens/chat_screen.dart';
import 'package:taller_ceramica/screens/crear_taller.dart';
import 'package:taller_ceramica/screens/login.dart';
import 'package:taller_ceramica/screens/home_screen.dart';
import 'package:taller_ceramica/screens/mis_clases.dart';
import 'package:taller_ceramica/screens/gestion_clases_screen.dart';
import 'package:taller_ceramica/screens/gestion_horarios_screen.dart';
import 'package:taller_ceramica/screens/prueba.dart';
import 'package:taller_ceramica/screens/responsive_turnos_screen/responsive_clases_screen.dart';
import 'package:taller_ceramica/screens/sign_up_screen.dart';
import 'package:taller_ceramica/screens/subscription_screen.dart';
import 'package:taller_ceramica/screens/usuarios_screen.dart';
import 'package:taller_ceramica/screens/configuracion.dart';
import 'package:taller_ceramica/screens/cambiar_password.dart';
import 'package:taller_ceramica/screens/update_name_screen.dart';
import 'package:taller_ceramica/screens/welcome_screen.dart';

final appRouter = GoRouter(
  initialLocation: "/",
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: "/login",
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: "/home/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return HomeScreen(
          taller: tallerParam,
        );
      },
    ),
    GoRoute(
      path: "/turnos/:taller",
      builder: (context, state) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final tallerParam = state.pathParameters['taller'];
        return ResposiveClasesScreen(
          isTablet: isTablet,
          taller: tallerParam,
        );
      },
    ),
    GoRoute(
      path: "/misclases/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return MisClasesScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/gestionhorarios/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return GestionHorariosScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/usuarios/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return UsuariosScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/configuracion/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return Configuracion(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/crear-usuario/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return SignUpScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/prueba",
      builder: (context, state) => const Prueba(),
    ),
    GoRoute(
      path: "/gestionclases/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return GestionDeClasesScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/cambiarpassword",
      builder: (context, state) => const CambiarPassword(),
    ),
    GoRoute(
      path: "/cambiarfullname/:taller",
      builder: (context, state) {
        final tallerParam = state.pathParameters['taller'];
        return UpdateNameScreen(taller: tallerParam);
      },
    ),
    GoRoute(
      path: "/creartaller",
      builder: (context, state) => const CrearTallerScreen(),
    ),
    GoRoute(
      path: "/subscription",
      builder: (context, state) => SubscriptionScreen(),
    ),
    GoRoute(
      path: "/chatscreen",
      builder: (context, state) => ChatScreen(),
    ),
    
 
    
  ],
);
