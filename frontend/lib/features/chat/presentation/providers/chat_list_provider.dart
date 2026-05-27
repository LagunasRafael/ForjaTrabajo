import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart'; 
import '../../domain/entities/chat_summary_entity.dart';
import '../../domain/repositories/chat_repository.dart';


final chatListProvider = StateNotifierProvider.autoDispose<ChatListNotifier, AsyncValue<List<ChatSummaryEntity>>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatListNotifier(repository);
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<ChatSummaryEntity>>> {
  final ChatRepository repository;

  ChatListNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadRealChats();
  }

  Future<void> loadRealChats() async {
    try {
      final chats = await repository.getUserChats();
      if (!mounted) return;
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    await loadRealChats();
  }

  Future<void> toggleArchiveStatus(String chatId, bool archive) async {
    if (!mounted) return;
    final currentChats = state.value ?? [];
    
    final updatedChats = currentChats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(isArchived: archive);
      }
      return chat;
    }).toList();

    state = AsyncValue.data(updatedChats);

    try {
      await repository.archiveChat(chatId, archive);
    } catch (e) {
      if (!mounted) return;
      // Rollback: restaurar el estado anterior si falla
      state = AsyncValue.data(currentChats);
      print("Error archivando: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (!mounted) return;
    final currentChats = state.value ?? [];
    
    final updatedChats = currentChats.where((chat) => chat.id != chatId).toList();
    state = AsyncValue.data(updatedChats);

    try {
      await repository.deleteChat(chatId);
    } catch (e) {
      if (!mounted) return;
      // Rollback: restaurar el estado anterior si falla
      state = AsyncValue.data(currentChats);
      print("Error eliminando chat: $e");
    }
  }

  /// Marca localmente un chat como leído para feedback instantáneo
  void markAsReadLocal(String chatId) {
    if (!mounted) return;
    final current = state.value;
    if (current == null) return;
    
    final updatedChats = current.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(hasUnread: false);
      }
      return chat;
    }).toList();

    state = AsyncValue.data(updatedChats);
  }
}
