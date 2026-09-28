import 'dart:convert';

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
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:8080',
          ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<HealthStatus> getHealth() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/health'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('API mengembalikan status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response API tidak valid');
    }

    return HealthStatus.fromJson(decoded);
  }

  @override
  void close() {
    _client.close();
  }
}
