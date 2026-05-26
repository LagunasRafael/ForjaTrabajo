import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Payment> processPayment(Payment payment);
  Future<List<Payment>> getPaymentHistory();
  Future<Map<String, dynamic>> createPaymentIntent(double amountMxn, String workerId, String jobId);
  Future<void> confirmPayment({
    required String paymentIntentId,
    required String workerId,
    required double amountMxn,
    required String jobId,
  });
  Future<Payment> confirmEscrow(String paymentIntentId);
}
