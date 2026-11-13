import 'dart:convert';

import 'package:http/http.dart' as http;

/// Configuración del backend ASP.NET Core.
/// - Emulador Android: usar `https://10.0.2.2:PUERTO`
/// - Dispositivo físico: IP de la PC en la red local.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localhost:7215',
  );
  static const Duration timeout = Duration(seconds: 20);
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP mínimo (REST + JSON sobre HTTPS).
class ApiClient {
  final http.Client _http;
  final String baseUrl;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _headers(String? instructorId) => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'X-Instructor-Id': ?instructorId,
      };

  Future<dynamic> get(String path, {String? instructorId}) async {
    final res = await _http
        .get(Uri.parse('$baseUrl$path'), headers: _headers(instructorId))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<http.Response> postRaw(String path, Object body, {String? instructorId}) {
    return _http
        .post(Uri.parse('$baseUrl$path'),
            headers: _headers(instructorId), body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(res.body, statusCode: res.statusCode);
  }
}
