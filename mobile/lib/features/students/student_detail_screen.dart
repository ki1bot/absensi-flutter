import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({required this.studentId, super.key});

  final int studentId;

  @override
  State<StudentDetailScreen> createState() {
    return _StudentDetailScreenState();
  }
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _api = ApiClient();

  Map<String, dynamic>? _student;
  String? _qrPayload;

  bool _loadingQR = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _api.close();

    super.dispose();
  }

  Future<void> _load() async {
    try {
      final student = await _api.get('/api/v1/students/${widget.studentId}');

      if (mounted) {
        setState(() {
          _student = Map<String, dynamic>.from(student);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _loadQR() async {
    setState(() {
      _loadingQR = true;
    });

    try {
      final result = await _api.get(
        '/api/v1/students/'
        '${widget.studentId}/qr',
      );

      if (mounted) {
        setState(() {
          _qrPayload = result['payload'].toString();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingQR = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Siswa')),
      body: student == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppPanel(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        child: Text(
                          student['name'].toString().isEmpty
                              ? '?'
                              : student['name'].toString()[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['name'].toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student['class_name']}  •  NIS ${student['nis']}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionTitle(title: 'Informasi siswa'),
                const SizedBox(height: 12),
                AppPanel(
                  child: Column(
                    children: [
                      AppInfoRow(
                        label: 'NIS',
                        value: student['nis'].toString(),
                        icon: Icons.badge_outlined,
                      ),
                      const Divider(),
                      AppInfoRow(
                        label: 'Kelas',
                        value: student['class_name'].toString(),
                        icon: Icons.class_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle(title: 'Orang tua'),
                const SizedBox(height: 12),
                AppPanel(
                  child: Column(
                    children: [
                      AppInfoRow(
                        label: 'Nama',
                        value: student['guardian_name'].toString(),
                        icon: Icons.person_outline_rounded,
                      ),
                      const Divider(),
                      AppInfoRow(
                        label: 'Email',
                        value: student['guardian_email'].toString(),
                        icon: Icons.mail_outline,
                      ),
                      const Divider(),
                      AppInfoRow(
                        label: 'No. HP',
                        value: student['guardian_phone'].toString(),
                        icon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionTitle(
                  title: 'QR Absensi',
                  subtitle: 'QR ini digunakan saat proses absensi siswa.',
                ),
                const SizedBox(height: 12),
                AppPanel(
                  child: Column(
                    children: [
                      if (_qrPayload == null)
                        Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.qr_code_2,
                                size: 38,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tampilkan QR untuk kartu absensi siswa.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _loadingQR ? null : _loadQR,
                                icon: const Icon(Icons.qr_code_rounded),
                                label: Text(
                                  _loadingQR ? 'Memuat...' : 'Tampilkan QR',
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: QrImageView(data: _qrPayload!, size: 220),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'QR hanya digunakan untuk proses absensi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
