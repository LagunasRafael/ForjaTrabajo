class Payment {
  final String id;
  final double amount;
  final int amountCents;
  final String contractId;
  final String status;
  final DateTime date; 
  final String paymentMethod;
  final String? stripePaymentIntentId;

  Payment({
    required this.id,
    required this.amount,
    this.amountCents = 0,
    required this.contractId,
    required this.status,
    required this.date,
    required this.paymentMethod,
    this.stripePaymentIntentId,
  });
}