import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../injection_container.dart' as di;
import '../../data/models/payment_model.dart';
import '../../domain/usescases/get_payment_history.dart';

final walletProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final useCase = di.sl<GetPaymentHistory>();
  final payments = await useCase();
  return payments.map((p) => p is PaymentModel ? p : PaymentModel(
    id: p.id,
    contractId: p.contractId,
    amount: p.amount,
    amountCents: p.amountCents,
    status: p.status,
    date: p.date,
    paymentMethod: p.paymentMethod,
    stripePaymentIntentId: p.stripePaymentIntentId,
    serviceTitle: p.serviceTitle,
    serviceDescription: p.serviceDescription,
    serviceCategory: p.serviceCategory,
  )).toList();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(walletProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mi Billetera',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: paymentsAsync.when(
        data: (payments) {
          final completed = payments.where((p) => p.status == 'completed' || p.status == 'released').toList();
          final total = completed.fold(0.0, (sum, p) => sum + p.amount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(walletProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalCard(context, total, completed.length),
                const SizedBox(height: 24),
                Text('Historial de pagos',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (completed.isEmpty)
                  _buildEmptyState()
                else
                  ...completed.map((p) => _buildPaymentCard(context, p)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F13EC), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F13EC).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ganancias totales',
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count pago${count == 1 ? '' : 's'} completado${count == 1 ? '' : 's'}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    final isCompleted = payment.status == 'completed' || payment.status == 'released';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successEmerald.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? LucideIcons.checkCircle : LucideIcons.clock,
              color: isCompleted ? AppTheme.successEmerald : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.serviceTitle ?? 'Servicio',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${payment.date.day}/${payment.date.month}/${payment.date.year}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text('\$${payment.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? AppTheme.successEmerald
                      : Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(LucideIcons.wallet, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aún no tienes pagos',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Los pagos completados aparecerán aquí.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
