import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taller_ceramica/screens/soporte_chat_screen.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import '../providers/twilio_provider.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay conversaciones activas por ahora.'),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final c = list[index];

              print("LA DATA IMPORTANTE $c");

              // Obtenemos el nombre o número de usuario
              final rawName = c['user_name'] ?? 'Desconocido';
              final name = rawName;

              final sid = c['sid'] ?? 'Sin SID';

              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(name),
                subtitle: Text('SID: $sid'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SoporteChatScreen(conversationSid: sid),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
