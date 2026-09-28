import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.service,
    required this.database,
    required this.time,
  });

  final String status;
  final String service;
  final String database;
  final DateTime? time;

  bool get isHealthy => status == 'ok' && database == 'connected';

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      database: json['database']?.toString() ?? '',
      time: DateTime.tryParse(json['time']?.toString() ?? ''),
    );
  }
}

abstract class HealthService {
  Future<HealthStatus> getHealth();

  void close();
}

class HealthApi implements HealthService {
  HealthApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? _resolveBaseUrl(),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static String _resolveBaseUrl() {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    return 'http://127.0.0.1:8080';
  }

  @override
  Future<HealthStatus> getHealth() async {
    final uri = Uri.parse('$baseUrl/health');

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception('API mengembalikan status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response API tidak valid');
    }

    final health = HealthStatus.fromJson(decoded);

    if (health.status.isEmpty ||
        health.service.isEmpty ||
        health.database.isEmpty) {
      throw const FormatException('Response health API tidak lengkap');
    }

    return health;
  }

  @override
  void close() {
    _client.close();
  }
}
