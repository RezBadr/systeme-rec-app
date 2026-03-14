import 'dart:convert';

import 'package:http/http.dart' as http;

/// A very small HTTP client wrapper for calling the Hono backend.
///
/// Update [baseUrl] to point to your running backend instance.
class ApiService {
  ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Map<String, String> _defaultHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(
    String path, {
    String? token,
  }) async {
    final uri = _uri(path);
    final response = await http.get(uri, headers: _defaultHeaders(token: token));
    return _decodeResponse(response);
  }

  static Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final uri = _uri(path);
    final response = await http.post(uri,
        headers: _defaultHeaders(token: token), body: jsonEncode(body));
    return _decodeResponse(response);
  }

  static dynamic _decodeResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw ApiException(
        message: 'Empty response body',
        statusCode: response.statusCode,
      );
    }

    final parsed = jsonDecode(body);
    if (parsed is! Map<String, dynamic>) {
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = parsed['success'] as bool? ?? false;
      if (!success) {
        final error = parsed['error'] ?? 'Erreur inconnue';
        throw ApiException(
          message: error.toString(),
          statusCode: response.statusCode,
          body: parsed['message']?.toString(),
        );
      }

      return parsed['data'];
    }

    final error = parsed['error'] ?? parsed['message'] ?? 'Erreur serveur';
    throw ApiException(
      message: error.toString(),
      statusCode: response.statusCode,
      body: parsed['message']?.toString(),
    );
  }
}

class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode, this.body});

  final String message;
  final int statusCode;
  final String? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
