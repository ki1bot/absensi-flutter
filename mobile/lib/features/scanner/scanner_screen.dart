import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() {
    return _ScannerScreenState();
  }
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _api = ApiClient();

  final _controller = MobileScannerController();

  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    _api.close();

    super.dispose();
  }

  Future<void> _process(BarcodeCapture capture) async {
    if (_processing) {
      return;
    }

    final value = capture.barcodes.firstOrNull?.rawValue;

    if (value == null || !value.startsWith('ABSENSI:')) {
      return;
    }

    setState(() => _processing = true);

    await _controller.stop();

    try {
      final result = await _api.post(
        '/api/v1/attendance/check-in',
        body: {'qr_token': value},
      );

      if (!mounted) {
        return;
      }

      final student = Map<String, dynamic>.from(result['student']);

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
            title: const Text('Absensi Berhasil'),
            content: Text(
              '${student['name']}\n'
              'Kelas ${student['class']}\n'
              'Pukul ${result['time']}\n'
              '${result['status'] == 'late' ? 'Terlambat' : 'Hadir'}',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Scan Lagi'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Absensi gagal'),
              content: Text(error.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);

        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Absen Masuk')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _process),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Arahkan kamera ke QR siswa',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
