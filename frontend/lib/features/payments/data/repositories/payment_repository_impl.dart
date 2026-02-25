import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Payment> processPayment(PaymentModel payment) async {
    try {
      final paymentModel = await remoteDataSource.processPayment(payment);
      return paymentModel; // PaymentModel suele heredar de Payment
    } catch (e) {
      throw Exception('Fallo en el repositorio de pagos: $e');
    }
  }

 @override
Future<List<Payment>> getPaymentHistory() async {
  try {
    // 1. Llamamos al DataSource que ya configuraste
    final paymentModels = await remoteDataSource.getPaymentHistory();
    
    // 2. Devolvemos la lista (los modelos ya funcionan como entidades)
    return paymentModels;
  } catch (e) {
    throw Exception('Error en el repositorio al obtener historial: $e');
  }
}
}