import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() {
    return _AttendanceScreenState();
  }
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _api = ApiClient();

  List<dynamic> _values = [];

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
    final result = await _api.get('/api/v1/attendances');

    if (mounted) {
      setState(() {
        _values = result as List<dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _values.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = Map<String, dynamic>.from(_values[index]);

            final time = DateTime.tryParse(item['scanned_at'].toString());

            final status = item['status'].toString();

            return Card(
              child: ListTile(
                leading: Icon(
                  status == 'late' ? Icons.schedule : Icons.check_circle,
                  color: status == 'late' ? Colors.orange : Colors.green,
                ),
                title: Text(item['name'].toString()),
                subtitle: Text(
                  '${item['class_name']} • '
                  '${time == null ? '-' : DateFormat('dd MMM yyyy • HH:mm').format(time.toLocal())}',
                ),
                trailing: Text(status == 'late' ? 'Terlambat' : 'Hadir'),
              ),
            );
          },
        ),
      ),
    );
  }
}
