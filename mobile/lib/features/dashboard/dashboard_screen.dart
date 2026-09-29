import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/theme_controller.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';
import '../auth/auth_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _api = ApiClient();

  Map<String, dynamic>? _stats;
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
      final result = await _api.get('/api/v1/dashboard');

      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(result);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
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
            tooltip: 'Profil admin',
            onPressed: () {
              context.push('/admin/profile');
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Halo, ${user?.name ?? 'Admin'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Berikut kondisi kehadiran siswa hari ini.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),
            const SectionTitle(
              title: 'Ringkasan',
              subtitle: 'Data kehadiran hari ini',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: _StatCard(
                          label: 'Total Siswa',
                          value: '${_stats?['total_students'] ?? 0}',
                          icon: Icons.groups_2_outlined,
                          foreground: scheme.primary,
                          background: scheme.primaryContainer,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _StatCard(
                          label: 'Hadir',
                          value: '${_stats?['present_today'] ?? 0}',
                          icon: Icons.check_circle_outline_rounded,
                          foreground: AppColors.success,
                          background: AppColors.successSoft,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _StatCard(
                          label: 'Terlambat',
                          value: '${_stats?['late_today'] ?? 0}',
                          icon: Icons.schedule_rounded,
                          foreground: AppColors.warning,
                          background: AppColors.warningSoft,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _StatCard(
                          label: 'Belum Hadir',
                          value: '${_stats?['not_present'] ?? 0}',
                          icon: Icons.person_off_outlined,
                          foreground: scheme.onSurfaceVariant,
                          background: scheme.surfaceContainer,
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 30),
            const SectionTitle(
              title: 'Menu',
              subtitle: 'Kelola kegiatan absensi sekolah',
            ),
            const SizedBox(height: 12),
            AppActionTile(
              icon: Icons.people_outline_rounded,
              title: 'Data Siswa',
              subtitle: 'Tambah, lihat, dan ubah data siswa',
              onTap: () {
                context.push('/students');
              },
            ),
            const SizedBox(height: 10),
            AppActionTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Absensi',
              subtitle: 'Pindai QR siswa untuk mencatat kehadiran',
              onTap: () {
                context.push('/scanner');
              },
            ),
            const SizedBox(height: 10),
            AppActionTile(
              icon: Icons.history_rounded,
              title: 'Riwayat Absensi',
              subtitle: 'Lihat catatan siswa yang sudah melakukan absensi',
              onTap: () {
                context.push('/attendances');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(
            icon: icon,
            size: 38,
            iconSize: 20,
            backgroundColor: background,
            foregroundColor: foreground,
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
