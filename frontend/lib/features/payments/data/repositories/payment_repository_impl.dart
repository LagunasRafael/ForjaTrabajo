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
      return paymentModel;
    } catch (e) {
      throw Exception('Fallo en el repositorio de pagos: $e');
    }
  }

  @override
  Future<List<Payment>> getPaymentHistory() async {
    try {
      final paymentModels = await remoteDataSource.getPaymentHistory();
      return paymentModels;
    } catch (e) {
      throw Exception('Error en el repositorio al obtener historial: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent(String jobId, double amount) async {
    try {
      return await remoteDataSource.createPaymentIntent(jobId, amount);
    } catch (e) {
      throw Exception('Error al crear intent de pago: $e');
    }
  }

  @override
  Future<Payment> confirmEscrow(String paymentIntentId) async {
    try {
      return await remoteDataSource.confirmEscrow(paymentIntentId);
    } catch (e) {
      throw Exception('Error al confirmar garantía: $e');
    }
  }
}