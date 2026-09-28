import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
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
  bool _loading = true;

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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await _api.get('/api/v1/attendances');

      if (mounted) {
        setState(() {
          _values = result as List<dynamic>;
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _values.isEmpty
          ? RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Belum ada riwayat',
                    message: 'Data absensi akan muncul setelah siswa melakukan scan.',
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: _values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = Map<String, dynamic>.from(_values[index]);

                  final time = DateTime.tryParse(item['scanned_at'].toString());

                  final status = item['status'].toString();

                  final late = status == 'late';

                  return AppPanel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: late
                                ? AppColors.warningSoft
                                : AppColors.successSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            late ? Icons.schedule_rounded : Icons.check_rounded,
                            color: late ? AppColors.warning : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${item['class_name']}'),
                              const SizedBox(height: 3),
                              Text(
                                time == null
                                    ? '-'
                                    : DateFormat('dd MMM yyyy, HH:mm')
                                          .format(time.toLocal()),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: late ? 'Terlambat' : 'Hadir',
                          foregroundColor: late
                              ? AppColors.warning
                              : AppColors.success,
                          backgroundColor: late
                              ? AppColors.warningSoft
                              : AppColors.successSoft,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
