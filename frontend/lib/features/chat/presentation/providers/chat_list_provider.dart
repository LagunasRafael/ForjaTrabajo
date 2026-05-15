import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
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

  StreamSubscription? _notifSubscription;

  ChatListNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadRealChats();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notifSubscription = NotificationService.onNotification.listen((message) {
      final type = message.data['type'];
      print("🔔 [ChatListProvider] Notificación recibida: $type");
      
      if (type == 'new_message' || type == 'admin_message' || type == 'dispute_opened' || type == 'new_offer') {
        print("🔄 [ChatListProvider] Recargando lista de chats...");
        loadRealChats();
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadRealChats() async {
    try {
      final chats = await repository.getUserChats();
<<<<<<< HEAD
      if (!mounted) return;
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      if (!mounted) return;
=======
      if (_disposed) return;
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      if (_disposed) return;
>>>>>>> develop
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
<<<<<<< HEAD
      if (!mounted) return;
      // Rollback: restaurar el estado anterior si falla
=======
      if (_disposed) return;
>>>>>>> develop
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
<<<<<<< HEAD
      if (!mounted) return;
      // Rollback: restaurar el estado anterior si falla
      state = AsyncValue.data(currentChats);
=======
      if (_disposed) return;
      state = AsyncData(currentChats);
>>>>>>> develop
      print("Error eliminando chat: $e");
    }
  }

<<<<<<< HEAD
  /// Marca localmente un chat como leído para feedback instantáneo
  void markAsReadLocal(String chatId) {
    final current = state.value;
    if (current == null) return;
    
    final updatedChats = current.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(hasUnread: false);
      }
      return chat;
    }).toList();

    state = AsyncValue.data(updatedChats);
=======
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
>>>>>>> develop
  }
}