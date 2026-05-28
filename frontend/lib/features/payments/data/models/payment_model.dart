import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  PaymentModel({
    required super.id,
    required super.contractId,
    required super.amount,
    required super.amountCents,
    required super.status,
    required super.date,
    required super.paymentMethod,
    super.stripePaymentIntentId,
    super.jobId,
    super.serviceId,
    super.serviceTitle,
    super.serviceDescription,
    super.serviceCategory,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      contractId: json['contract_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      amountCents: json['amount_cents'] ?? 0,
      status: json['status'] ?? 'pending',
      date: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['date'] != null ? DateTime.parse(json['date']) : DateTime.now()),
      paymentMethod: json['payment_method'] ?? '',
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      jobId: json['job_id']?.toString(),
      serviceId: json['service_id']?.toString(),
      serviceTitle: json['service_title']?.toString(),
      serviceDescription: json['service_description']?.toString(),
      serviceCategory: json['service_category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'amount': amount,
      'amount_cents': amountCents,
      'status': status,
      'date': date.toIso8601String(),
      if (stripePaymentIntentId != null) 'stripe_payment_intent_id': stripePaymentIntentId,
    };
  }
}
