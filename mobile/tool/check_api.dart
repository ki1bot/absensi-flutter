import 'dart:io';

import 'package:absensi_flutter/services/health_api.dart';

Future<void> main(List<String> arguments) async {
  final baseUrl = arguments.isNotEmpty
      ? arguments.first
      : Platform.environment['API_BASE_URL'] ?? 'http://backend:8080';

  final api = HealthApi(baseUrl: baseUrl);

  try {
    final health = await api.getHealth();

    stdout.writeln('API Base URL : $baseUrl');
    stdout.writeln('Status       : ${health.status}');
    stdout.writeln('Service      : ${health.service}');
    stdout.writeln('Database     : ${health.database}');
    stdout.writeln('Time         : ${health.time}');

    if (!health.isHealthy) {
      stderr.writeln('Koneksi belum sehat.');
      exitCode = 1;
    }
  } catch (error) {
    stderr.writeln('Gagal terhubung ke API: $error');
    exitCode = 1;
  } finally {
    api.close();
  }
}
