import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';

enum _AttendanceFilter { all, present, late }

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

  _AttendanceFilter _filter = _AttendanceFilter.all;

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

  List<dynamic> get _filteredValues {
    switch (_filter) {
      case _AttendanceFilter.present:
        return _values.where((value) {
          final item = Map<String, dynamic>.from(value);

          return item['status'].toString() != 'late';
        }).toList();

      case _AttendanceFilter.late:
        return _values.where((value) {
          final item = Map<String, dynamic>.from(value);

          return item['status'].toString() == 'late';
        }).toList();

      case _AttendanceFilter.all:
        return _values;
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = _filteredValues;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const PageIntro(
                    title: 'Riwayat kehadiran',
                    subtitle: 'Catatan siswa yang sudah melakukan absensi.',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _filter == _AttendanceFilter.all,
                        onSelected: (_) {
                          setState(() {
                            _filter = _AttendanceFilter.all;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Hadir'),
                        selected: _filter == _AttendanceFilter.present,
                        onSelected: (_) {
                          setState(() {
                            _filter = _AttendanceFilter.present;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Terlambat'),
                        selected: _filter == _AttendanceFilter.late,
                        onSelected: (_) {
                          setState(() {
                            _filter = _AttendanceFilter.late;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (values.isEmpty)
                    const EmptyState(
                      icon: Icons.history_rounded,
                      title: 'Belum ada riwayat',
                      message: 'Data absensi akan muncul setelah siswa melakukan scan.',
                    )
                  else
                    ...values.map((value) {
                      final item = Map<String, dynamic>.from(value);

                      final time = DateTime.tryParse(
                        item['scanned_at'].toString(),
                      );

                      final late = item['status'].toString() == 'late';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: AppPanel(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              AppIconBox(
                                icon: late
                                    ? Icons.schedule_rounded
                                    : Icons.check_rounded,
                                backgroundColor: late
                                    ? AppColors.warningSoft
                                    : AppColors.successSoft,
                                foregroundColor: late
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 13),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      item['class_name'].toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      time == null
                                          ? '-'
                                          : DateFormat('dd MMM yyyy · HH:mm')
                                                .format(time.toLocal()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
