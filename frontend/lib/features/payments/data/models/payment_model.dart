import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  PaymentModel({
    required super.id,
    required super.contractId,
    required super.amount,
    required super.status,
    required super.date,
    required super.paymentMethod,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      contractId: json['contract_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      date: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['date'] != null ? DateTime.parse(json['date']) : DateTime.now()),
      paymentMethod: json['payment_method'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(), // Convierte la fecha a texto para el servidor
    };
  }
}