import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';

class RegisterSchoolScreen extends StatefulWidget {
  const RegisterSchoolScreen({super.key});

  @override
  State<RegisterSchoolScreen> createState() {
    return _RegisterSchoolScreenState();
  }
}

class _RegisterSchoolScreenState extends State<RegisterSchoolScreen> {
  final _api = ApiClient();

  final _schoolController = TextEditingController();

  final _adminController = TextEditingController();

  final _emailController = TextEditingController();

  final _entryController = TextEditingController(text: '07:00');

  bool _loading = false;

  @override
  void dispose() {
    _api.close();
    _schoolController.dispose();
    _adminController.dispose();
    _emailController.dispose();
    _entryController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      final response = await _api.post(
        '/api/v1/schools/register',
        authenticated: false,
        body: {
          'school_name': _schoolController.text.trim(),
          'admin_name': _adminController.text.trim(),
          'entry_time': _entryController.text.trim(),
          'email': _emailController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      final map = Map<String, dynamic>.from(response);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sekolah berhasil didaftarkan'),
            content: SelectableText(
              'Email admin:\n'
              '${map['admin_email']}\n\n'
              'Password awal:\n'
              '${map['initial_password']}\n\n'
              'Simpan password ini. '
              'Password hanya ditampilkan sekarang.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Saya Simpan'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        context.go('/login');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Sekolah')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _schoolController,
              decoration: const InputDecoration(labelText: 'Nama Sekolah'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adminController,
              decoration: const InputDecoration(labelText: 'Nama Admin'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _entryController,
              decoration: const InputDecoration(
                labelText: 'Jam Masuk',
                hintText: '07:00',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Admin'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: const Text('Daftar Sekolah'),
            ),
          ],
        ),
      ),
    );
  }
}
