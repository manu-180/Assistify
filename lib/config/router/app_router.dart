import 'package:go_router/go_router.dart';
import 'package:assistify/screens/chat_screen.dart';
import 'package:assistify/screens/conversation_list_screen.dart';
import 'package:assistify/screens/crear_taller.dart';
import 'package:assistify/screens/login.dart';
import 'package:assistify/screens/home_screen.dart';
import 'package:assistify/screens/mis_clases.dart';
import 'package:assistify/screens/gestion_clases_screen.dart';
import 'package:assistify/screens/gestion_horarios_screen.dart';
import 'package:assistify/screens/onboarding_screen.dart';
import 'package:assistify/screens/prueba.dart';
import 'package:assistify/screens/clases_screen.dart';
import 'package:assistify/screens/subscription_screen.dart';
import 'package:assistify/screens/usuarios_screen.dart';
import 'package:assistify/screens/configuracion.dart';
import 'package:assistify/screens/welcome_screen.dart';

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
        final tallerParam = state.pathParameters['taller'];
        return ClasesScreen(
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
    GoRoute(
      path: '/soporte',
      name: 'soporte',
      builder: (context, state) => const ConversationListScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);
