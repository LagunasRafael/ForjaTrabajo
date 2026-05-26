import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ProcessPayment {
  final PaymentRepository repository;

  ProcessPayment(this.repository);

  Future<Payment> call(Payment payment) async {
    return await repository.processPayment(payment);
  }
}