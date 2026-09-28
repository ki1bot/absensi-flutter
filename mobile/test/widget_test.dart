import 'package:absensi_flutter/main.dart';
import 'package:absensi_flutter/services/health_api.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHealthService implements HealthService {
  @override
  Future<HealthStatus> getHealth() async {
    return HealthStatus(
      status: 'ok',
      service: 'absensi-api',
      database: 'connected',
      time: DateTime.utc(2026, 9, 28, 10, 37, 57),
    );
  }

  @override
  void close() {}
}

void main() {
  testWidgets('menampilkan status API dan database terhubung', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AbsensiApp(healthService: FakeHealthService()));

    await tester.pumpAndSettle();

    expect(find.text('Absensi Mobile App'), findsOneWidget);

    expect(find.text('Flutter → Go → PostgreSQL'), findsOneWidget);

    expect(find.text('API terhubung'), findsOneWidget);

    expect(find.text('ok'), findsOneWidget);

    expect(find.text('absensi-api'), findsOneWidget);

    expect(find.text('connected'), findsOneWidget);
  });
}
