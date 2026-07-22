import 'package:dio/dio.dart';

final Dio apiClient = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
  // The PHP API uses JSON bodies for both successful and rejected requests.
  // Let SQLResponse interpret 401/403/409/422 instead of turning them into
  // indistinguishable network exceptions.
  validateStatus: (status) => status != null && status >= 200 && status < 600,
));
