import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({TokenStorage? tokenStorage, http.Client? client})
    : _tokenStorage = tokenStorage ?? const TokenStorage(),
      _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  Future<dynamic> get(String path) async {
    return _request(method: 'GET', path: path);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<dynamic> delete(String path) async {
    return _request(method: 'DELETE', path: path);
  }

  Future<dynamic> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final accessToken = await _tokenStorage.readAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    late http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;

      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
        break;

      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;

      default:
        throw const ApiException('HTTP method tidak didukung');
    }

    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request gagal (${response.statusCode})';

      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }

      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }

  void close() {
    _client.close();
  }
}
