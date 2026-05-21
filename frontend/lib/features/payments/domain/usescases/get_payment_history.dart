import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistory {
  final PaymentRepository repository;

  GetPaymentHistory(this.repository);

  Future<List<Payment>> call() async {
    return await repository.getPaymentHistory(); // Ejemplo de ID de contrato
  }
}