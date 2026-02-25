import 'package:dio/dio.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> processPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPaymentHistory();
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      // Usamos la ruta base que ya probamos en Swagger
      final response = await dio.get('/payments/');

      if (response.statusCode == 200) {
        final List data = response.data;
        // Mapea la lista de JSON a objetos PaymentModel
        return data.map((json) => PaymentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      print("Error en getPaymentHistory: $e");
      throw Exception('Error de conexión al historial: $e');
    }
  }

  @override
  Future<PaymentModel> processPayment(PaymentModel payment) async {
    try {
      // Enviamos el pago al backend usando POST
      // Asegúrate de que payment.toJson() mande 'contract_id' y 'amount'
      final response = await dio.post(
        '/payments/',
        data: payment.toJson(),
      );

      // El backend devuelve 201 Created cuando el pago es exitoso
      if (response.statusCode == 201 || response.statusCode == 200) {
        return PaymentModel.fromJson(response.data);
      } else {
        throw Exception('Error al procesar pago: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Imprimimos el error exacto del servidor (como el 400 o 500)
      print("Error en processPayment: ${e.response?.data ?? e.message}");
      throw Exception('Error de red al pagar: ${e.message}');
    }
  }
}