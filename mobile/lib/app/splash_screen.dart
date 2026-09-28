import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import 'theme.dart';

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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'E-Absensi Siswa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
