import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/providers/api_client_provider.dart';
import '../../domain/repositories/service_repository.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../data/datasources/category_remote_data_source.dart';
import '../../data/datasources/service_remote_data_source.dart';
import '../../data/datasources/service_request_remote_data_source.dart';
import '../../data/datasources/job_remote_data_source.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider),
    dio: apiClient.dio,
  );
});
