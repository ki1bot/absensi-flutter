import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
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
            const SizedBox(height: 5),
            const Text('Berikut ringkasan kehadiran siswa hari ini.'),
            const SizedBox(height: 26),
            const SectionTitle(
              title: 'Ringkasan hari ini',
              subtitle: 'Tarik halaman ke bawah untuk memperbarui data.',
            ),
            const SizedBox(height: 14),
            if (_loading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _StatCard(
                    title: 'Total Siswa',
                    value: '${_stats?['total_students'] ?? 0}',
                    icon: Icons.groups_2_outlined,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primarySoft,
                  ),
                  _StatCard(
                    title: 'Hadir',
                    value: '${_stats?['present_today'] ?? 0}',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    backgroundColor: AppColors.successSoft,
                  ),
                  _StatCard(
                    title: 'Terlambat',
                    value: '${_stats?['late_today'] ?? 0}',
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                    backgroundColor: AppColors.warningSoft,
                  ),
                  _StatCard(
                    title: 'Belum Hadir',
                    value: '${_stats?['not_present'] ?? 0}',
                    icon: Icons.person_off_outlined,
                    color: AppColors.textSecondary,
                    backgroundColor: AppColors.background,
                  ),
                ],
              ),
            const SizedBox(height: 28),
            const SectionTitle(
              title: 'Menu utama',
              subtitle: 'Kelola siswa dan proses absensi.',
            ),
            const SizedBox(height: 14),
            _MenuTile(
              icon: Icons.people_outline_rounded,
              title: 'Data Siswa',
              subtitle: 'Lihat, cari, dan tambah data siswa',
              onTap: () {
                context.push('/students');
              },
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Absensi',
              subtitle: 'Pindai QR siswa saat datang',
              onTap: () {
                context.push('/scanner');
              },
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.history_rounded,
              title: 'Riwayat Absensi',
              subtitle: 'Lihat catatan kehadiran siswa',
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
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        minTileHeight: 76,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
