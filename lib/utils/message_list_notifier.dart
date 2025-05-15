import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/twilio_service.dart';

class MessageListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final TwilioService service;
  final String conversationSid;

  MessageListNotifier(this.service, this.conversationSid)
      : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final msgs = await service.fetchMessages(conversationSid);
      state = AsyncData(msgs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refreshIfChanged() async {
    try {
      final newMsgs = await service.fetchMessages(conversationSid);
      if (state is AsyncData) {
        final currentMsgs = (state as AsyncData).value;
        if (currentMsgs.length != newMsgs.length) {
          state = AsyncData(newMsgs);
        }
      }
    } catch (_) {
      // Ignoramos errores si ya está renderizado
    }
  }

  void forceRefresh() => _load();
}
