import '../../domain/entities/payment.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final Payment payment; 
  PaymentSuccess(this.payment);
}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
}