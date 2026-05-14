import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart'; 
import '../../domain/entities/chat_summary_entity.dart';
import '../../domain/repositories/chat_repository.dart';


final chatListProvider = StateNotifierProvider<ChatListNotifier, AsyncValue<List<ChatSummaryEntity>>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatListNotifier(repository);
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<ChatSummaryEntity>>> {
  final ChatRepository repository;
  bool _disposed = false;

  ChatListNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadRealChats();
  }

  Future<void> loadRealChats() async {
    try {
      final chats = await repository.getUserChats();
      if (_disposed) return;
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      if (_disposed) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;
    state = const AsyncValue.loading();
    await loadRealChats();
  }

  Future<void> toggleArchiveStatus(String chatId, bool archive) async {
    if (_disposed) return;
    final currentChats = state.value ?? [];
    
    final updatedChats = currentChats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(isArchived: archive);
      }
      return chat;
    }).toList();

    state = AsyncData(updatedChats);

    try {
      await repository.archiveChat(chatId, archive);
    } catch (e) {
      if (_disposed) return;
      state = AsyncData(currentChats);
      print("Error archivando: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    if (_disposed) return;
    final currentChats = state.value ?? [];
    
    final updatedChats = currentChats.where((chat) => chat.id != chatId).toList();
    state = AsyncData(updatedChats);

    try {
      await repository.deleteChat(chatId);
    } catch (e) {
      if (_disposed) return;
      state = AsyncData(currentChats);
      print("Error eliminando chat: $e");
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}