class Payment {
  final String id;
  final double amount;
  final int amountCents;
  final double platformFee;
  final double stripeFee;
  final double? netPayout;
  final String contractId;
  final String status;
  final DateTime date;
  final String paymentMethod;
  final String? stripePaymentIntentId;
  final String? jobId;
  final String? serviceId;
  final String? serviceTitle;
  final String? serviceDescription;
  final String? serviceCategory;

  const Payment({
    required this.id,
    required this.amount,
    required this.amountCents,
    this.platformFee = 0.0,
    this.stripeFee = 0.0,
    this.netPayout,
    required this.contractId,
    required this.status,
    required this.date,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    this.jobId,
    this.serviceId,
    this.serviceTitle,
    this.serviceDescription,
    this.serviceCategory,
  });

  double get netAmount =>
      netPayout ?? (platformFee > 0 || stripeFee > 0
          ? amount - platformFee - stripeFee
          : amount * 0.9);
}
