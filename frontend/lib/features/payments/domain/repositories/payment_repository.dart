import '../entities/payment.dart';
import '../../data/models/payment_model.dart';

abstract class PaymentRepository {
  Future<Payment> processPayment(PaymentModel payment);
  Future<List<Payment>> getPaymentHistory();
  Future<Map<String, dynamic>> createPaymentIntent(String jobId, double amount);
  Future<Payment> confirmEscrow(String paymentIntentId);
}