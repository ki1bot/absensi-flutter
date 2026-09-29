import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/theme_controller.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';
import '../auth/auth_controller.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() {
    return _AdminProfileScreenState();
  }
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authControllerProvider).user;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _api.close();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await _api.put(
        '/api/v1/admin/profile',
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      final map = Map<String, dynamic>.from(result);

      final user = AppUser.fromJson(Map<String, dynamic>.from(map['user']));

      ref.read(authControllerProvider.notifier).updateUser(user);

      _passwordController.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Profil admin berhasil diperbarui')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
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
    ref.watch(themeControllerProvider);

    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Admin')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      name.isEmpty ? 'A' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Admin' : name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 5),
                        const StatusBadge(
                          label: 'Administrator',
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primarySoft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const SectionTitle(
                title: 'Informasi akun',
                subtitle: 'Perubahan tersimpan langsung ke akun admin',
              ),
              const SizedBox(height: 12),
              AppPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Nama Admin',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }

                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        helperText: 'Kosongkan apabila password tidak diubah.',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 8) {
                          return 'Password minimal 8 karakter';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Preferensi'),
              const SizedBox(height: 12),
              AppPanel(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  value: dark,
                  onChanged: (value) {
                    ref.read(themeControllerProvider.notifier).setDark(value);
                  },
                  secondary: AppIconBox(
                    icon: dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    backgroundColor: scheme.surfaceContainer,
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  title: const Text(
                    'Tema gelap',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    dark
                        ? 'Tema gelap sedang digunakan'
                        : 'Tema terang sedang digunakan',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Sesi akun'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
