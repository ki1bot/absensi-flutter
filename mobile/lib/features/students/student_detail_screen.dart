import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    final student = await _api.get('/api/v1/students/${widget.studentId}');

    if (mounted) {
      setState(() {
        _student = Map<String, dynamic>.from(student);
      });
    }
  }

  Future<void> _loadQR() async {
    final result = await _api.get(
      '/api/v1/students/'
      '${widget.studentId}/qr',
    );

    if (mounted) {
      setState(() {
        _qrPayload = result['payload'].toString();
      });
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
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  student['name'].toString(),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('NIS: ${student['nis']}'),
                Text(
                  'Kelas: '
                  '${student['class_name']}',
                ),
                Text(
                  'Orang Tua: '
                  '${student['guardian_name']}',
                ),
                Text(
                  'Email: '
                  '${student['guardian_email']}',
                ),
                Text(
                  'No. HP: '
                  '${student['guardian_phone']}',
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Lihat QR'),
                ),
                if (_qrPayload != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: QrImageView(data: _qrPayload!, size: 240),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
