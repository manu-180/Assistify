import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import '../providers/twilio_provider.dart';
import '../services/twilio_service.dart';

class SoporteChatScreen extends ConsumerStatefulWidget {
  final String conversationSid;
  const SoporteChatScreen({super.key, required this.conversationSid});

  @override
  ConsumerState<SoporteChatScreen> createState() => _SoporteChatScreenState();
}

class _SoporteChatScreenState extends ConsumerState<SoporteChatScreen> {
  late final TextEditingController controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    final messagesNotifier = ref.read(messagesProvider(widget.conversationSid).notifier);
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      messagesNotifier.refreshIfChanged();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationSid));
    final service = ref.read(twilioServiceProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  final body = msg['body'] ?? '';
                  final author = msg['author'] ?? '';
                  final media = msg['media'] ?? [];

                  final isOwn = author.contains('system');
                  final bgColor = isOwn
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary.withOpacity(0.2);
                  final align = isOwn ? Alignment.centerRight : Alignment.centerLeft;
                  final textColor = isOwn ? Colors.white : Colors.black87;

                  // 🧠 MEDIA (audio / imagen / otros)
                  if (media.isNotEmpty) {
                    final mediaItem = media[0];
                    final mediaSid = mediaItem['sid'];
                    final contentType = mediaItem['content_type'] ?? '';

                    return FutureBuilder<String>(
                      future: service.getMediaUrl(mediaSid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Text('Media no disponible');
                        }

                        final mediaUrl = snapshot.data!;

                        // 🎵 AUDIO
                        if (contentType.contains('audio')) {
                          final player = AudioPlayer();
                          return Align(
                            alignment: align,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.play_arrow, color: textColor),
                                onPressed: () async {
                                  await player.play(UrlSource(mediaUrl));
                                },
                              ),
                            ),
                          );
                        }

                        // 🖼️ IMAGE
                        if (contentType.contains('image')) {
                          return Align(
                            alignment: align,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  mediaUrl,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }

                        // ❓ OTRO
                        return Align(
                          alignment: align,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Contenido: $contentType',
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // ✅ MENSAJE DE TEXTO
                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        body,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Escribí un mensaje...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      await service.sendMessage(widget.conversationSid, text);
                      controller.clear();
                      ref.invalidate(messagesProvider(widget.conversationSid));
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
  

    );
  }
}
