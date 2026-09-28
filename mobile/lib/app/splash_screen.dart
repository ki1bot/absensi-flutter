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

      case 'operator':
        context.go('/scanner');

      default:
        context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
