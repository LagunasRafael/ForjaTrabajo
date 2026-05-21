import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/network/api_client.dart';

class WalletStatus {
  final bool hasStripeAccount;
  final bool onboardingCompleted;
  final bool chargesEnabled;
  final bool payoutsEnabled;

  const WalletStatus({
    this.hasStripeAccount = false,
    this.onboardingCompleted = false,
    this.chargesEnabled = false,
    this.payoutsEnabled = false,
  });

  bool get isReady => onboardingCompleted && chargesEnabled && payoutsEnabled;
}

final walletStatusProvider = FutureProvider<WalletStatus>((ref) async {
  try {
    final response = await ApiClient().dio.get('/workers/stripe-status');
    final data = response.data;
    return WalletStatus(
      hasStripeAccount: data['has_stripe_account'] ?? false,
      onboardingCompleted: data['onboarding_completed'] ?? false,
      chargesEnabled: data['charges_enabled'] ?? false,
      payoutsEnabled: data['payouts_enabled'] ?? false,
    );
  } catch (_) {
    return const WalletStatus();
  }
});
