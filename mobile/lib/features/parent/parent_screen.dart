import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final dashboard = await _api.get('/api/v1/parent/dashboard');

    final notifications = await _api.get('/api/v1/notifications');

    if (mounted) {
      setState(() {
        _children = dashboard['children'] as List<dynamic>;

        _notifications = notifications as List<dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orang Tua'),
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
              'Halo, ${user?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ..._children.map((value) {
              final child = Map<String, dynamic>.from(value);

              final status = child['status'].toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['name'].toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Kelas '
                        '${child['class_name']}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        status.isEmpty
                            ? 'Belum hadir hari ini'
                            : status == 'late'
                            ? 'Terlambat • ${child['time']}'
                            : 'Hadir • ${child['time']}',
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text('Notifikasi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._notifications.map((value) {
              final notification = Map<String, dynamic>.from(value);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notification['title'].toString()),
                  subtitle: Text(notification['body'].toString()),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
