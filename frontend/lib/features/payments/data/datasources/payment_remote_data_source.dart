import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> processPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPaymentHistory();
  Future<Map<String, dynamic>> createPaymentIntent(double amountMxn, String workerId, String jobId);
  Future<void> confirmPayment({
    required String paymentIntentId,
    required String workerId,
    required double amountMxn,
    required String jobId,
  });
  Future<PaymentModel> confirmEscrow(String paymentIntentId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;
  final _storage = const FlutterSecureStorage();

  PaymentRemoteDataSourceImpl({required this.dio});

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  @override
  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      final token = await _getToken();
      final response = await dio.get(
        '/payments/',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => PaymentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al historial: $e');
    }
  }

  @override
  Future<PaymentModel> processPayment(PaymentModel payment) async {
    try {
      final token = await _getToken();
      final response = await dio.post(
        '/payments/create-intent',
        data: {
          'job_id': payment.contractId,
          'amount': payment.amount,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return PaymentModel(
          id: response.data['payment_intent_id'] ?? '',
          contractId: payment.contractId,
          amount: payment.amount,
          amountCents: (payment.amount * 100).toInt(),
          status: 'pending_escrow',
          date: DateTime.now(),
          paymentMethod: payment.paymentMethod,
          stripePaymentIntentId: response.data['client_secret'],
        );
      } else {
        throw Exception('Error al procesar pago: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error de red al pagar: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent(double amountMxn, String workerId, String jobId) async {
    try {
      final token = await _getToken();
      final response = await dio.post(
        '/payments/create-intent',
        data: {
          'amount_mxn': amountMxn,
          'worker_id': workerId,
          'job_id': jobId,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Error al crear PaymentIntent: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al crear intent de pago: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<void> confirmPayment({
    required String paymentIntentId,
    required String workerId,
    required double amountMxn,
    required String jobId,
  }) async {
    try {
      final token = await _getToken();
      await dio.post(
        '/payments/confirm-payment',
        data: {
          'payment_intent_id': paymentIntentId,
          'worker_id': workerId,
          'amount_mxn': amountMxn,
          'job_id': jobId,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception('Error al confirmar pago: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<PaymentModel> confirmEscrow(String paymentIntentId) async {
    try {
      final token = await _getToken();
      final response = await dio.post(
        '/payments/confirm-escrow',
        data: {
          'payment_intent_id': paymentIntentId,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentModel.fromJson(response.data);
      } else {
        throw Exception('Error al confirmar escrow: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error al confirmar garantía: ${e.response?.data ?? e.message}');
    }
  }
}
