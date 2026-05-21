import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';

/// Cuenta cuántos chats activos tienen mensajes no leídos.
/// Se actualiza automáticamente cuando el chatListProvider cambia.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final chatState = ref.watch(chatListProvider);
  return chatState.maybeWhen(
    data: (chats) => chats.where((c) => c.hasUnread && !c.isArchived).length,
    orElse: () => 0,
  );
});
