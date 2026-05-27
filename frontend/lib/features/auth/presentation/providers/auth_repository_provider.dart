import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dataSource = AuthRemoteDataSource(apiClient: apiClient);
  return AuthRepositoryImpl(dataSource: dataSource);
});
