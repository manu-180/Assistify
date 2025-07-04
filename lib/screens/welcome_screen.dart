import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assistify/supabase/utiles/redirijir_usuario_al_taller.dart';
import 'package:video_player/video_player.dart';
import 'dart:io' show Platform;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<VideoPlayerController> _controllers = [];

  int _currentPage = 0;
  bool _allInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _initVideos();
  }

  Future<void> _initVideos() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _allInitialized = true;
      });
      return;
    }

    _controllers = [
      VideoPlayerController.asset('assets/videos/video1.mp4'),
      VideoPlayerController.asset('assets/videos/video2.mp4'),
      VideoPlayerController.asset('assets/videos/video3.mp4'),
    ];

    for (var controller in _controllers) {
      await controller.initialize();
      controller.setLooping(false);
      controller.setVolume(0.0);
    }

    if (_controllers.isNotEmpty) {
      _controllers[_currentPage].play();
      _controllers[_currentPage].addListener(_videoListener);
    }

    if (mounted) {
      setState(() {
        _allInitialized = true;
      });
    }
  }

  void _videoListener() {
    if (_controllers.isEmpty) return;
    final controller = _controllers[_currentPage];
    if (controller.value.position >= controller.value.duration &&
        !controller.value.isPlaying) {
      controller.removeListener(_videoListener);
      final nextPage = (_currentPage + 1) % _controllers.length;

      setState(() {
        _currentPage = nextPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controllers.isNotEmpty) {
          _controllers[nextPage].play();
          _controllers[nextPage].addListener(_videoListener);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await RedirigirUsuarioAlTaller().redirigirUsuario(context);
    }
  }

  List<Widget> _buildTextAndButtons(Size size) {
    return [
      const Text(
        '¿Sos empresa?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: "oxanium",
        ),
        textAlign: TextAlign.center,
      ),
      Column(
        children: [
          OutlinedButton(
            onPressed: () => context.push("/onboarding"),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(size.width * 0.8, 50),
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Crea tu cuenta',
                style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: size.width * 0.04),
          OutlinedButton(
            onPressed: () => context.push("/login"),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(size.width * 0.8, 50),
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Inicia sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      const Text(
        '¿Sos alumno?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: "oxanium",
        ),
        textAlign: TextAlign.center,
      ),
      OutlinedButton(
        onPressed: () => context.push("/login"),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(size.width * 0.8, 50),
          side: const BorderSide(color: Colors.white),
        ),
        child:
            const Text('Inicia sesión', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            width: size.width,
            child: isWide
                ? Row(
                    children: [
                      // VIDEO A LA IZQUIERDA
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: _allInitialized
                                ? AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 800),
                                    switchInCurve: Curves.easeIn,
                                    switchOutCurve: Curves.easeOut,
                                    child: _controllers.isNotEmpty
                                        ? VideoPlayer(
                                            _controllers[_currentPage],
                                            key: UniqueKey(),
                                          )
                                        : const Center(
                                            child: Text(
                                                "Vista previa no disponible"),
                                          ),
                                  )
                                : Shimmer.fromColors(
  baseColor: const Color.fromARGB(255, 33, 33, 33),
  highlightColor: Colors.grey.shade700,
  child: Container(
    color: Colors.black,
  ),
)
,
                          ),
                        ),
                      ),

                      // CONTENIDO A LA DERECHA
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _buildTextAndButtons(size),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: size.height * 0.02),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: SizedBox(
                            height: size.height * 0.5,
                            width: size.width * 0.8,
                            child: _allInitialized
                                ? AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 800),
                                    switchInCurve: Curves.easeIn,
                                    switchOutCurve: Curves.easeOut,
                                    child: _controllers.isNotEmpty
                                        ? VideoPlayer(
                                            _controllers[_currentPage],
                                            key: UniqueKey(),
                                          )
                                        : const Center(
                                            child: Text(
                                                "Vista previa no disponible"),
                                          ),
                                  )
                                :Shimmer.fromColors(
  baseColor: const Color.fromARGB(255, 33, 33, 33),
  highlightColor: Colors.grey.shade700,
  child: Container(
    color: Colors.black,
  ),
)



,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            size.height * 0.03,
                            0,
                            size.height * 0.03,
                            size.height * 0.03,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _buildTextAndButtons(size),
                          ),
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
