import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    try {
      final result = await _api.get('/api/v1/dashboard');

      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(result);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Halo, ${user?.name ?? 'Admin'}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('Pantau kehadiran siswa hari ini.'),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _StatCard(
                    title: 'Total Siswa',
                    value: '${_stats?['total_students'] ?? 0}',
                    icon: Icons.groups_outlined,
                  ),
                  _StatCard(
                    title: 'Hadir Hari Ini',
                    value: '${_stats?['present_today'] ?? 0}',
                    icon: Icons.check_circle_outline,
                  ),
                  _StatCard(
                    title: 'Terlambat',
                    value: '${_stats?['late_today'] ?? 0}',
                    icon: Icons.schedule,
                  ),
                  _StatCard(
                    title: 'Belum Hadir',
                    value: '${_stats?['not_present'] ?? 0}',
                    icon: Icons.person_off_outlined,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            _MenuButton(
              icon: Icons.people,
              title: 'Data Siswa',
              onTap: () {
                context.push('/students');
              },
            ),
            _MenuButton(
              icon: Icons.qr_code_scanner,
              title: 'Scan Absensi',
              onTap: () {
                context.push('/scanner');
              },
            ),
            _MenuButton(
              icon: Icons.history,
              title: 'Riwayat Absensi',
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
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
