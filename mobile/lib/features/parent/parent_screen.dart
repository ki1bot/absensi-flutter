import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/theme_controller.dart';
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

    ref.watch(themeControllerProvider);

    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            tooltip: dark ? 'Tema terang' : 'Tema gelap',
            onPressed: () {
              ref.read(themeControllerProvider.notifier).setDark(!dark);
            },
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
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
                    'Halo, ${user?.name ?? 'Orang Tua'}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau informasi kehadiran anak dari sini.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle(title: 'Kehadiran hari ini'),
                  const SizedBox(height: 12),
                  if (_children.isEmpty)
                    const EmptyState(
                      icon: Icons.person_outline_rounded,
                      title: 'Belum ada siswa',
                      message: 'Belum ada data siswa yang terhubung dengan akun ini.',
                    )
                  else
                    ..._children.map((value) {
                      final child = Map<String, dynamic>.from(value);

                      final status = child['status'].toString();
                      final late = status == 'late';
                      final present = status.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: AppPanel(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                child: Text(
                                  child['name'].toString().isEmpty
                                      ? '?'
                                      : child['name']
                                            .toString()[0]
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kelas ${child['class_name']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    if (present) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Tercatat pukul ${child['time']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: !present
                                    ? 'Belum Hadir'
                                    : late
                                    ? 'Terlambat'
                                    : 'Hadir',
                                foregroundColor: !present
                                    ? scheme.onSurfaceVariant
                                    : late
                                    ? AppColors.warning
                                    : AppColors.success,
                                backgroundColor: !present
                                    ? scheme.surfaceContainer
                                    : late
                                    ? AppColors.warningSoft
                                    : AppColors.successSoft,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 26),
                  SectionTitle(
                    title: 'Pemberitahuan',
                    subtitle: '${_notifications.length} notifikasi',
                  ),
                  const SizedBox(height: 12),
                  if (_notifications.isEmpty)
                    const AppPanel(child: Text('Belum ada pemberitahuan baru.'))
                  else
                    ..._notifications.map((value) {
                      final notification = Map<String, dynamic>.from(value);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: AppPanel(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            minTileHeight: 74,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            leading: AppIconBox(
                              icon: Icons.notifications_none_rounded,
                              backgroundColor: scheme.surfaceContainer,
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                            title: Text(
                              notification['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(notification['body'].toString()),
                            ),
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
