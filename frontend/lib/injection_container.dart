import 'package:forja_trabajo/core/utils/api_config.dart';
import 'package:forja_trabajo/features/payments/domain/usescases/get_payment_history.dart';
import 'package:forja_trabajo/features/payments/domain/usescases/process_payment.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:forja_trabajo/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:forja_trabajo/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:forja_trabajo/features/payments/domain/repositories/payment_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  
  sl.registerFactory(() => ProcessPayment(sl()));
  sl.registerLazySingleton(() => GetPaymentHistory(sl()));

  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: sl()),
  );

  // 3. Data Sources
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton(() => Dio(BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
)));

  // Use cases
 
  
}