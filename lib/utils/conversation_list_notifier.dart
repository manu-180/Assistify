import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/twilio_service.dart';

class ConversationListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final TwilioService service;
  Timer? _timer;

  ConversationListNotifier(this.service) : super(const AsyncLoading()) {
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetch()); // refresca cada 10s
  }

  Future<void> _fetch() async {
  try {
    final rawConversations = await service.fetchConversations();
    
    final enriched = await Future.wait(rawConversations.map((conv) async {
      final sid = conv['sid'];
      final userName = await service.fetchFirstParticipantIdentity(sid);
      print("🧪EL USER NAME ES $userName");
      return {
        ...conv,
        'user_name': userName ?? 'Desconocido',
      };
    }));

    state = AsyncData(enriched);
  } catch (e, st) {
    state = AsyncError(e, st);
  }
}


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
 