import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../presentation/providers/public_profile_provider.dart';

final verificationDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VerificationRemoteDataSource(apiClient: apiClient);
});

class VerificationRemoteDataSource {
  final ApiClient apiClient;

  VerificationRemoteDataSource({required this.apiClient});

  Future<Map<String, dynamic>> uploadVerification({
    required File ineFront,
    required File ineBack,
    required File selfie,
  }) async {
    final formData = FormData.fromMap({
      'ine_front': await MultipartFile.fromFile(ineFront.path, filename: 'ine_front.jpg'),
      'ine_back': await MultipartFile.fromFile(ineBack.path, filename: 'ine_back.jpg'),
      'selfie': await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });

    final response = await apiClient.dio.post(
      '/auth/verify-identity',
      data: formData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getVerificationStatus() async {
    final response = await apiClient.dio.get('/auth/verification-status');
    return response.data;
  }
}
