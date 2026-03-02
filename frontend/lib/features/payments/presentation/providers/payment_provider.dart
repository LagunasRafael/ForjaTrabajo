import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Usa este, no legacy
import 'package:forja_trabajo/features/payments/domain/entities/payment.dart';
import '../../data/models/payment_model.dart';
import '../../domain/usescases/process_payment.dart';
import '../../domain/usescases/get_payment_history.dart'; // 2. IMPORTANTE: Tu caso de uso
import 'payment_state.dart';
import '../../../../../injection_container.dart'; // Ajusta los puntos si es necesario

// --- NOTIFIER PARA PROCESAR EL PAGO (YA LO TENÍAS) ---
class PaymentNotifier extends StateNotifier<PaymentState> {
  final ProcessPayment processPaymentUseCase;

  PaymentNotifier({required this.processPaymentUseCase}) : super(PaymentInitial());

  Future<void> pay(PaymentModel payment) async {
    state = PaymentLoading();
    try {
      final result = await processPaymentUseCase(payment);
      state = PaymentSuccess(result);
    } catch (e) {
      state = PaymentError(e.toString());
    }
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(processPaymentUseCase: sl<ProcessPayment>());
});



final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final getHistoryUseCase = sl<GetPaymentHistory>();
  return await getHistoryUseCase(); 
});