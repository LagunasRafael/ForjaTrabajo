import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Usa este, no legacy
import 'package:forja_trabajo/features/payments/domain/entities/payment.dart';
import '../../data/models/payment_model.dart';
import '../../domain/usescases/process_payment.dart';
import '../../domain/usescases/get_payment_history.dart'; // 2. IMPORTANTE: Tu caso de uso
import 'payment_state.dart';
import '../../../../../injection_container.dart'; // Ajusta los puntos si es necesario

import '../../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return sl<PaymentRepository>();
});

// --- NOTIFIER PARA PROCESAR EL PAGO (YA LO TENÍAS) ---
class PaymentNotifier extends StateNotifier<PaymentState> {
  final ProcessPayment processPaymentUseCase;
  final PaymentRepository repository;

  PaymentNotifier({
    required this.processPaymentUseCase,
    required this.repository,
  }) : super(PaymentInitial());

  Future<void> pay(PaymentModel payment) async {
    state = PaymentLoading();
    try {
      final result = await processPaymentUseCase(payment);
      state = PaymentSuccess(result);
    } catch (e) {
      state = PaymentError(e.toString());
    }
  }

  Future<Map<String, dynamic>> createIntent(double amountMxn, String workerId) async {
    state = PaymentLoading();
    try {
      final result = await repository.createPaymentIntent(amountMxn, workerId);
      return result;
    } catch (e) {
      state = PaymentError(e.toString());
      rethrow;
    }
  }

  Future<void> confirmPayment({
    required String paymentIntentId,
    required String workerId,
    required double amountMxn,
    required String jobId,
  }) async {
    try {
      await repository.confirmPayment(
        paymentIntentId: paymentIntentId,
        workerId: workerId,
        amountMxn: amountMxn,
        jobId: jobId,
      );
    } catch (e) {
      state = PaymentError(e.toString());
      rethrow;
    }
  }

  Future<void> confirmEscrow(String paymentIntentId) async {
    try {
      await repository.confirmEscrow(paymentIntentId);
      state = PaymentSuccess(null); // O un estado específico de Escrow
    } catch (e) {
      state = PaymentError(e.toString());
      rethrow;
    }
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    processPaymentUseCase: sl<ProcessPayment>(),
    repository: sl<PaymentRepository>(),
  );
});



final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final getHistoryUseCase = sl<GetPaymentHistory>();
  return await getHistoryUseCase(); 
});