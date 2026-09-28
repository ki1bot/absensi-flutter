import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';
import '../auth/auth_controller.dart';

class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() {
    return _ParentScreenState();
  }
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  final _api = ApiClient();

  List<dynamic> _children = [];
  List<dynamic> _notifications = [];

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
      final dashboard = await _api.get('/api/v1/parent/dashboard');

      final notifications = await _api.get('/api/v1/notifications');

      if (mounted) {
        setState(() {
          _children = dashboard['children'] as List<dynamic>;

          _notifications = notifications as List<dynamic>;
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

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Absensi'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Halo, ${user?.name ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  const Text('Pantau status kehadiran anak Anda hari ini.'),
                  const SizedBox(height: 26),
                  const SectionTitle(title: 'Kehadiran hari ini'),
                  const SizedBox(height: 12),
                  if (_children.isEmpty)
                    const AppPanel(
                      child: Text(
                        'Belum ada data siswa yang terhubung dengan akun ini.',
                      ),
                    )
                  else
                    ..._children.map((value) {
                      final child = Map<String, dynamic>.from(value);

                      final status = child['status'].toString();

                      final late = status == 'late';

                      final present = status.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppPanel(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primarySoft,
                                foregroundColor: AppColors.primary,
                                child: const Icon(Icons.person_rounded),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text('Kelas ${child['class_name']}'),
                                    if (present) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pukul ${child['time']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: !present
                                    ? 'Belum Hadir'
                                    : late
                                    ? 'Terlambat'
                                    : 'Hadir',
                                foregroundColor: !present
                                    ? AppColors.textSecondary
                                    : late
                                    ? AppColors.warning
                                    : AppColors.success,
                                backgroundColor: !present
                                    ? AppColors.background
                                    : late
                                    ? AppColors.warningSoft
                                    : AppColors.successSoft,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'Notifikasi',
                    subtitle: '${_notifications.length} pemberitahuan',
                  ),
                  const SizedBox(height: 12),
                  if (_notifications.isEmpty)
                    const AppPanel(child: Text('Belum ada notifikasi baru.'))
                  else
                    ..._notifications.map((value) {
                      final notification = Map<String, dynamic>.from(value);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppPanel(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            minTileHeight: 72,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.primary,
                                size: 21,
                              ),
                            ),
                            title: Text(
                              notification['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(notification['body'].toString()),
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
