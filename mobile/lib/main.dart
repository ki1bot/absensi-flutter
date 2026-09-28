import 'package:flutter/material.dart';

import 'services/health_api.dart';

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key, this.healthService});

  final HealthService? healthService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomePage(healthService: healthService),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.healthService});

  final HealthService? healthService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HealthService _healthService;

  HealthStatus? _health;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _healthService = widget.healthService ?? HealthApi();

    _checkHealth();
  }

  Future<void> _checkHealth() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final health = await _healthService.getHealth();

      if (!mounted) {
        return;
      }

      setState(() {
        _health = health;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _health = null;
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _healthService.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = _health;

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    health?.isHealthy == true
                        ? Icons.check_circle
                        : _error != null
                        ? Icons.error
                        : Icons.sync,
                    size: 96,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Absensi Mobile App',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Flutter → Go → PostgreSQL',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memeriksa koneksi API...'),
                      ],
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!)
                  else if (health != null)
                    _HealthCard(health: health),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _checkHealth,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Periksa Kembali'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final HealthStatus health;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              health.isHealthy ? 'API terhubung' : 'API bermasalah',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _StatusRow(label: 'Status', value: health.status),
            const SizedBox(height: 12),
            _StatusRow(label: 'Service', value: health.service),
            const SizedBox(height: 12),
            _StatusRow(label: 'Database', value: health.database),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Waktu',
              value: health.time?.toLocal().toString() ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Gagal terhubung ke API',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SelectableText(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': '),
        Expanded(child: Text(value)),
      ],
    );
  }
}
