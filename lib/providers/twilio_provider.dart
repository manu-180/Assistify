import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/twilio_service.dart';

final twilioServiceProvider = Provider<TwilioService>((ref) {
  return TwilioService();
});

final conversationListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(twilioServiceProvider);
  return await service.fetchConversations();
});

final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sid) async {
  final service = ref.read(twilioServiceProvider);
  return await service.fetchMessages(sid);
});
