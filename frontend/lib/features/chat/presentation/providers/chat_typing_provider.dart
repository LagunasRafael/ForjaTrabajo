import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatTypingProvider = StateProvider.family<bool, String>((ref, conversationId) {
  return false;
});
