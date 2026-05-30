import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/wallet_status_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_repository_provider.dart';
import '../../../../injection_container.dart' as di;
import '../../data/models/payment_model.dart';
import '../../domain/usescases/get_payment_history.dart';

final walletProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final useCase = di.sl<GetPaymentHistory>();
  final payments = await useCase();
  final repo = ref.watch(serviceRepositoryProvider);

  List<PaymentModel> models = payments.map((p) => p is PaymentModel ? p : PaymentModel(
    id: p.id,
    contractId: p.contractId,
    amount: p.amount,
    amountCents: p.amountCents,
    platformFee: p.platformFee,
    stripeFee: p.stripeFee,
    netPayout: p.netPayout,
    status: p.status,
    date: p.date,
    paymentMethod: p.paymentMethod,
    stripePaymentIntentId: p.stripePaymentIntentId,
    jobId: p.jobId,
    serviceId: p.serviceId,
    serviceTitle: p.serviceTitle,
    serviceDescription: p.serviceDescription,
    serviceCategory: p.serviceCategory,
  )).toList();

  try {
    final services = await repo.getMyApplications();
    final serviceMap = {for (var s in services) s.id: s};
    final clientServices = await repo.getMyServices();
    for (var s in clientServices) {
      serviceMap.putIfAbsent(s.id, () => s);
    }

    models = models.map((pm) {
      if (pm.netPayout != null) return pm;
      if (pm.serviceId == null) return pm;
      final service = serviceMap[pm.serviceId];
      if (service == null) return pm;
      return PaymentModel(
        id: pm.id,
        contractId: pm.contractId,
        amount: pm.amount,
        amountCents: pm.amountCents,
        platformFee: service.platformFee ?? pm.platformFee,
        stripeFee: service.stripeFee ?? pm.stripeFee,
        netPayout: service.netPayout,
        status: pm.status,
        date: pm.date,
        paymentMethod: pm.paymentMethod,
        stripePaymentIntentId: pm.stripePaymentIntentId,
        jobId: pm.jobId,
        serviceId: pm.serviceId,
        serviceTitle: pm.serviceTitle ?? service.title,
        serviceDescription: pm.serviceDescription,
        serviceCategory: pm.serviceCategory,
      );
    }).toList();
  } catch (_) {}

  return models;
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with WidgetsBindingObserver {
  bool _isSettingUpWallet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(walletStatusProvider);
      ref.invalidate(walletProvider);
    }
  }

  Future<void> _setupWallet() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSettingUpWallet = true);

    try {
      final response = await ApiClient().dio.post(
        '/workers/stripe-setup',
        data: {'user_id': user.id},
      );

      final url = response.data['url'] as String;

      if (url == '__ALREADY_COMPLETED__') {
        ref.invalidate(walletStatusProvider);
        return;
      }

      if (mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al configurar billetera: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettingUpWallet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(walletProvider);
    final statusAsync = ref.watch(walletStatusProvider);
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
          final total = completed.fold(0.0, (sum, p) => sum + p.netAmount);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(walletProvider);
              ref.invalidate(walletStatusProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStripeBanner(statusAsync),
                if (statusAsync.valueOrNull?.isReady == true)
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

  Widget _buildStripeBanner(AsyncValue<WalletStatus> statusAsync) {
    final status = statusAsync.valueOrNull;
    if (status == null) return const SizedBox.shrink();
    if (status.isReady) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wallet, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Configura tu billetera',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitas configurar tu cuenta de Stripe para poder retirar el dinero de tus servicios.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSettingUpWallet ? null : _setupWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSettingUpWallet
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Configurar mi Billetera',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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
          Text('\$${payment.netAmount.toStringAsFixed(2)}',
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
