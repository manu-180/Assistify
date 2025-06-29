import 'package:assistify/config/router/app_router.dart';
import 'package:assistify/config/theme/app_theme.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/providers/theme_provider.dart';
import 'package:assistify/subscription/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;

// AssistifyPRUEBA MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await initializeDateFormatting('es_ES', null);

  // Solo escuchamos las compras desde el arranque
  final subscriptionManager = SubscriptionManager();
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    final subscriptionManager = SubscriptionManager();
    subscriptionManager.listenToPurchaseUpdates(
      onPurchase: (purchases) {
        print("Se recibieron compras nuevas: $purchases");
      },
    );
  }

  // 🟢 PostFrame: ejecutamos todo lo demás después del arranque visual
  runApp(
    ProviderScope(
      child: PostFrameWrapper(
        subscriptionManager: subscriptionManager,
        child: const MyApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppTheme themeNotify = ref.watch(themeNotifyProvider);

    return MaterialApp.router(
      title: "Assistify",
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: themeNotify.getColor(),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('pt'),
        Locale('de'),
        Locale('it'),
        Locale('zh'),
        Locale('ja'),
        Locale('ko'),
        Locale('ar'),
        Locale('hi'),
        Locale('ru'),
        Locale('tr'),
        Locale('nl'),
        Locale('sv'),
        Locale('pl'),
      ],
      // localeResolutionCallback: (locale, supportedLocales) {
      //   if (locale == null) {
      //     return const Locale('en');
      //   }

      //   for (var supportedLocale in supportedLocales) {
      //     if (supportedLocale.languageCode == locale.languageCode) {
      //       return supportedLocale;
      //     }
      //   }

      //   return const Locale('en');
      // },  PARA DESPUES
      locale: const Locale('es'),
    );
  }
}

class PostFrameWrapper extends StatefulWidget {
  final Widget child;
  final SubscriptionManager subscriptionManager;

  const PostFrameWrapper({
    super.key,
    required this.child,
    required this.subscriptionManager,
  });

  @override
  State<PostFrameWrapper> createState() => _PostFrameWrapperState();
}

class _PostFrameWrapperState extends State<PostFrameWrapper> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.subscriptionManager.restorePurchases();
      await widget.subscriptionManager.checkAndUpdateSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
