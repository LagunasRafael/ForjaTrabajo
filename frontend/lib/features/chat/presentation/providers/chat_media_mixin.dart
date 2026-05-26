import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';

mixin ChatMediaMixin on StateNotifier<List<MessageModel>> {
  ChatRepository get repository;
  String get conversationId;
  String get userId;
  Ref get ref;

  Future<void> sendMessage(String content, String type);

  Future<void> sendMediaBatch(List<String> paths, String? caption) async {
    if (paths.isEmpty) return;

    final audioPaths = paths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return ['m4a', 'mp3', 'ogg', 'wav', 'aac', 'opus'].contains(ext);
    }).toList();

    final imagePaths = paths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return !['m4a', 'mp3', 'ogg', 'wav', 'aac', 'opus'].contains(ext);
    }).toList();

    String? imageTempId;
    if (imagePaths.isNotEmpty) {
      imageTempId = 'temp_media_${DateTime.now().millisecondsSinceEpoch}';
      final localContent = imagePaths.join(',');
      final optimistic = MessageModel(
        id: imageTempId,
        conversationId: conversationId,
        senderId: userId,
        content: localContent,
        messageType: imagePaths.length > 1 ? 'gallery' : 'image',
        createdAt: DateTime.now().toUtc(),
        status: 'sending',
      );
      state = [optimistic, ...state];
      ref.read(chatListProvider.notifier).loadRealChats();
    }

    final audioTempIds = <String, String>{};
    for (final path in audioPaths) {
      final tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
      final optimistic = MessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: userId,
        content: path,
        messageType: 'audio',
        createdAt: DateTime.now().toUtc(),
        status: 'sending',
      );
      state = [optimistic, ...state];
      audioTempIds[tempId] = path;
    }

    if (imagePaths.isNotEmpty && imageTempId != null) {
      try {
        List<String> uploadedUrls = [];
        for (final path in imagePaths) {
          final url = await repository.uploadChatMedia(conversationId, path);
          if (url != null) uploadedUrls.add(url);
        }

        if (uploadedUrls.isNotEmpty) {
          final content = uploadedUrls.join(',');
          final type = uploadedUrls.length > 1 ? 'gallery' : 'image';
          
          try {
            final saved = await repository.sendMessageRest(conversationId, content, type);
            final idx = state.indexWhere((m) => m.id == imageTempId);
            if (idx != -1 && mounted) {
              state = [
                for (int i = 0; i < state.length; i++)
                  if (i == idx)
                    MessageModel(
                      id: saved.id,
                      conversationId: conversationId,
                      senderId: userId,
                      content: content,
                      messageType: type,
                      createdAt: saved.createdAt,
                      status: 'sent',
                    )
                  else
                    state[i],
              ];
            }
          } catch (e) {
            setMediaError(imageTempId);
          }
        } else {
          setMediaError(imageTempId);
        }
      } catch (e) {
        print("🚨 Error subiendo imágenes: $e");
        setMediaError(imageTempId);
      }
    }

    for (final entry in audioTempIds.entries) {
      final tempId = entry.key;
      final path = entry.value;
      try {
        final url = await repository.uploadChatMedia(conversationId, path);
        if (url != null) {
          try {
            final saved = await repository.sendMessageRest(conversationId, url, 'audio');
            final idx = state.indexWhere((m) => m.id == tempId);
            if (idx != -1 && mounted) {
              state = [
                for (int i = 0; i < state.length; i++)
                  if (i == idx)
                    MessageModel(
                      id: saved.id,
                      conversationId: conversationId,
                      senderId: userId,
                      content: url,
                      messageType: 'audio',
                      createdAt: saved.createdAt,
                      status: 'sent',
                    )
                  else
                    state[i],
              ];
            }
          } catch (e) {
            setMediaError(tempId);
          }
        } else {
          setMediaError(tempId);
        }
      } catch (e) {
        print("🚨 Error subiendo audio: $e");
        setMediaError(tempId);
      }
    }

    if (caption != null && caption.isNotEmpty) {
      await sendMessage(caption, 'text');
    }

    ref.read(chatListProvider.notifier).loadRealChats();
  }

  void setMediaError(String tempId) {
    final idx = state.indexWhere((m) => m.id == tempId);
    if (idx != -1 && mounted) {
      final old = state[idx];
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx)
            MessageModel(
              id: old.id,
              conversationId: old.conversationId,
              senderId: old.senderId,
              content: old.content,
              messageType: old.messageType,
              createdAt: old.createdAt,
              status: 'error',
            )
          else
            state[i],
      ];
    }
  }
}
