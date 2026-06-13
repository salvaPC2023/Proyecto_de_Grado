import 'package:dio/dio.dart';
import '../../domain/repositories/standardization_repository.dart';
import 'api_client.dart';

class StandardizationRepositoryImpl implements StandardizationRepository {
  StandardizationRepositoryImpl({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<String> standardize(String text) async {
    try {
      final res = await apiClient.dio.post(
        '/descriptions/standardize',
        data: {'text': text},
        options: Options(receiveTimeout: const Duration(seconds: 12)),
      );
      return (res.data as Map<String, dynamic>)['standardized_text'] as String;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 503 || status == 504) {
        final detail = (e.response?.data as Map<String, dynamic>?)?['detail'] as String?;
        throw StandardizationException(detail ?? 'Servicio no disponible');
      }
      throw const StandardizationException('Sin conexión al servidor');
    }
  }
}
