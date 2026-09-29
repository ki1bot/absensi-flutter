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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: late ? AppColors.warningSoft : AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                late ? Icons.schedule_rounded : Icons.check_rounded,
                color: late ? AppColors.warning : AppColors.success,
                size: 28,
              ),
            ),
            title: Text(late ? 'Absensi tercatat' : 'Absensi berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student['name'].toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Kelas ${student['class']}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  result['time'].toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  late ? 'Terlambat' : 'Hadir',
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
              size: 40,
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
          Container(color: Colors.black.withAlpha(36)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(170),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Arahkan QR ke area pemindaian',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(185),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _processing
                              ? Icons.hourglass_top_rounded
                              : Icons.info_outline_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _processing ? 'Memproses absensi siswa...' : 'Pastikan QR terlihat jelas dan berada di dalam kotak.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (_processing)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: SizedBox(
                              width: 18,
                              height: 18,
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
          ),
        ],
      ),
    );
  }
}
