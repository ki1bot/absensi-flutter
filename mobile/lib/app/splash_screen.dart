import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_restore);
  }

  Future<void> _restore() async {
    final restored = await ref.read(authControllerProvider.notifier).restore();

    if (!mounted) {
      return;
    }

    if (!restored) {
      context.go('/login');
      return;
    }

    final user = ref.read(authControllerProvider).user;

    switch (user?.role) {
      case 'parent':
        context.go('/parent');
        return;

      case 'operator':
        context.go('/scanner');
        return;

      case 'admin':
      default:
        context.go('/dashboard');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'E-Absensi Siswa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Pencatatan kehadiran sekolah',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 26),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
