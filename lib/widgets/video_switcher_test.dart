import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSwitcherTest extends StatefulWidget {
  const VideoSwitcherTest({super.key});

  @override
  State<VideoSwitcherTest> createState() => _VideoSwitcherTestState();
}

class _VideoSwitcherTestState extends State<VideoSwitcherTest> {
  final List<String> _videoPaths = [
    'assets/videos/video1.mp4',
    'assets/videos/video2.mp4',
    'assets/videos/video3.mp4',
  ];

  final List<String> _transitions = [
    'fade',
    'fade_to_black',
    'slide',
    'scale',
    'rotate',
    'fade_slide',
  ];

  late List<VideoPlayerController> _controllers;
  int _current = 0;
  bool _initialized = false;
  int _transitionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  Future<void> _initVideos() async {
    _controllers = _videoPaths.map((path) => VideoPlayerController.asset(path)).toList();
    for (var controller in _controllers) {
      await controller.initialize();
      controller.setLooping(false);
      controller.setVolume(0.0);
    }
    _playCurrent();
    setState(() => _initialized = true);
  }

  void _playCurrent() {
    _controllers[_current].play();
    _controllers[_current].addListener(_checkEnd);
  }

  void _checkEnd() {
    final controller = _controllers[_current];
    if (controller.value.position >= controller.value.duration && !controller.value.isPlaying) {
      controller.removeListener(_checkEnd);
      final next = (_current + 1) % _controllers.length;
      setState(() {
        _current = next;
      });
      _controllers[next].play();
      _controllers[next].addListener(_checkEnd);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    switch (_transitions[_transitionIndex]) {
      case 'fade_to_black':
        return FadeTransition(
          opacity: animation,
          child: Container(color: Colors.black, child: child),
        );
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut))
              .animate(animation),
          child: child,
        );
      case 'scale':
        return ScaleTransition(scale: animation, child: child);
      case 'rotate':
        return RotationTransition(turns: animation, child: child);
      case 'fade_slide':
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'fade':
      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Transición: ${_transitions[_transitionIndex]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                _transitionIndex = (_transitionIndex + 1) % _transitions.length;
              });
            },
          )
        ],
      ),
      body: Center(
        child: _initialized
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: _buildTransition,
                child: VideoPlayer(
                  _controllers[_current],
                  key: UniqueKey(),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
