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

  StreamSubscription? _notifSubscription;

  ChatListNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadRealChats();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notifSubscription = NotificationService.onNotification.listen((message) {
      final type = message.data['type'];
      // Si llega un nuevo mensaje, se abre una disputa o un mensaje de admin, refrescamos la lista
      if (type == 'new_message' || type == 'admin_message' || type == 'dispute_opened') {
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
      if (!mounted) return;
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await loadRealChats();
  }

  /// Actualización optimista: cambia la UI al instante, llama al backend, revierte si falla.
  Future<void> toggleArchiveStatus(String chatId, bool archive) async {
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
      if (!mounted) return;
      // Rollback: restaurar el estado anterior si falla
      state = AsyncData(currentChats);
      print("Error archivando: $e");
    }
  }

  /// Eliminación optimista: quita el chat de la UI, llama al backend, revierte si falla.
  Future<void> deleteChat(String chatId) async {
    final currentChats = state.value ?? [];
    
    final updatedChats = currentChats.where((chat) => chat.id != chatId).toList();
    state = AsyncData(updatedChats);

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