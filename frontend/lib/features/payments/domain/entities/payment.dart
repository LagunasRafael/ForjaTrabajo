class Payment {
  final String id;
  final double amount;
  final String contractId;
  final String status;
  final DateTime date; 
 final String paymentMethod; // Agrega el método de pago aquí

  Payment({
    required this.id,
    required this.amount,
    required this.contractId,
    required this.status,
    required this.date,
    required this.paymentMethod, // Asegúrate de incluirlo en el constructor
  });
}