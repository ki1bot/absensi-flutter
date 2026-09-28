import 'package:absensi_flutter/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menampilkan halaman login E-Absensi Siswa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('E-Absensi Siswa'), findsOneWidget);

    expect(
      find.text('Masuk sebagai Admin, Operator, atau Orang Tua'),
      findsOneWidget,
    );

    expect(find.text('Email'), findsOneWidget);

    expect(find.text('Password'), findsOneWidget);

    expect(find.text('Masuk'), findsOneWidget);

    expect(find.text('Daftarkan Sekolah'), findsOneWidget);
  });
}
