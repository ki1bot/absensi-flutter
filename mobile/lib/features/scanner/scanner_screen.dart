import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';
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
    if (_processing || capture.barcodes.isEmpty) {
      return;
    }

    final value = capture.barcodes.first.rawValue;

    if (value == null || !value.startsWith('ABSENSI:')) {
      return;
    }

    setState(() {
      _processing = true;
    });

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

      final late = result['status'] == 'late';

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: late ? AppColors.warningSoft : AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                late
                    ? Icons.schedule_rounded
                    : Icons.check_circle_outline_rounded,
                color: late ? AppColors.warning : AppColors.success,
                size: 30,
              ),
            ),
            title: Text(late ? 'Absensi Tercatat' : 'Absensi Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student['name'].toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Kelas ${student['class']}', textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(
                  'Pukul ${result['time']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  late ? 'Status: Terlambat' : 'Status: Hadir',
                  style: TextStyle(
                    color: late ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Scan Lagi'),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 42,
            ),
            title: const Text('Absensi gagal'),
            content: Text(error.toString(), textAlign: TextAlign.center),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Coba Lagi'),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });

        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Absensi'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () {
              _controller.toggleTorch();
            },
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Ganti kamera',
            onPressed: () {
              _controller.switchCamera();
            },
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _process),
          Container(color: Colors.black.withAlpha(24)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(155),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR siswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 255,
                  height: 255,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(170),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _processing
                              ? 'Memproses absensi...'
                              : 'Pastikan QR terlihat jelas di dalam kotak.',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (_processing)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
