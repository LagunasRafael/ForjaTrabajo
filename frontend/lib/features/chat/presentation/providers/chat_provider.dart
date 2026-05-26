import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:forja_trabajo/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_notifier.dart';

final chatDatasourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatDatasourceProvider);
  return ChatRepositoryImpl(remoteDataSource: dataSource);
});

final chatProvider = StateNotifierProvider.family.autoDispose<ChatNotifier, List<MessageModel>, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  final auth = ref.read(authProvider);
  final userId = auth.user?.id ?? '';
  
  return ChatNotifier(
    repository: repository,
    conversationId: conversationId,
    userId: userId,
    ref: ref,
  );
});
