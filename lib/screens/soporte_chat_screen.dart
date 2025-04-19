import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // ⏱️ Refrescamos cada 5 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(messagesProvider(widget.conversationSid));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), backgroundColor: Colors.teal.shade700),
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
                  return Align(
  alignment: msg['author'] == 'system' ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    decoration: BoxDecoration(
      color: msg['author'] == 'system'
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: msg['author'] == 'system'
            ? const Radius.circular(12)
            : const Radius.circular(0),
        bottomRight: msg['author'] == 'system'
            ? const Radius.circular(0)
            : const Radius.circular(12),
      ),
    ),
    child: Text(
      msg['body'] ?? '',
      style: TextStyle(
        color: msg['author'] == 'system' ? Colors.white : Colors.black87,
      ),
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
