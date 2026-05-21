import '../entities/payment.dart';
import '../repositories/payment_repository.dart';
import '../../data/models/payment_model.dart';

class ProcessPayment {
  final PaymentRepository repository;

  ProcessPayment(this.repository);

 
  Future<Payment> call(PaymentModel payment) async {
    
    return await repository.processPayment(payment);
  }
}