import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class CustomHttpClient {
  final http.Client _client = http.Client();

  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'User-Agent': 'Habitu/1.0.0 (Flutter)',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await _client
          .get(url, headers: _getHeaders(token: token))
          .timeout(timeout);

      _logResponse(
        method: 'GET',
        url: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      return response;
    } on Exception catch (e) {
      _logError(method: 'GET', url: endpoint, error: e.toString());
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      _logRequest(method: 'POST', url: endpoint, body: body);

      final response = await _client
          .post(
            url,
            headers: _getHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      _logResponse(
        method: 'POST',
        url: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      return response;
    } on Exception catch (e) {
      _logError(method: 'POST', url: endpoint, error: e.toString());
      rethrow;
    }
  }

  Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      _logRequest(method: 'PUT', url: endpoint, body: body);

      final response = await _client
          .put(
            url,
            headers: _getHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      _logResponse(
        method: 'PUT',
        url: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      return response;
    } on Exception catch (e) {
      _logError(method: 'PUT', url: endpoint, error: e.toString());
      rethrow;
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await _client
          .delete(url, headers: _getHeaders(token: token))
          .timeout(timeout);

      _logResponse(
        method: 'DELETE',
        url: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      return response;
    } on Exception catch (e) {
      _logError(method: 'DELETE', url: endpoint, error: e.toString());
      rethrow;
    }
  }

  void _logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
  }) {
    // Reserved for future structured logging.
  }

  void _logResponse({
    required String method,
    required String url,
    required int statusCode,
    required String responseBody,
  }) {
    // Reserved for future structured logging.
  }

  void _logError({
    required String method,
    required String url,
    required String error,
  }) {
    // Reserved for future structured logging.
  }

  void close() {
    _client.close();
  }
}
