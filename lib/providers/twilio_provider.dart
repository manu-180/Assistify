import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assistify/utils/conversation_list_notifier.dart';
import '../services/twilio_service.dart';
import '../utils/message_list_notifier.dart';

final twilioServiceProvider = Provider<TwilioService>((ref) {
  return TwilioService();
});

final conversationListProvider = StateNotifierProvider<ConversationListNotifier,
    AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => ConversationListNotifier(ref.read(twilioServiceProvider)),
);

final messagesProvider = StateNotifierProvider.family<MessageListNotifier,
    AsyncValue<List<Map<String, dynamic>>>, String>(
  (ref, sid) => MessageListNotifier(ref.read(twilioServiceProvider), sid),
);
