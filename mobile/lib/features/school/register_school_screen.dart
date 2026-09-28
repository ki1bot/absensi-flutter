import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_client.dart';

class RegisterSchoolScreen extends StatefulWidget {
  const RegisterSchoolScreen({super.key});

  @override
  State<RegisterSchoolScreen> createState() {
    return _RegisterSchoolScreenState();
  }
}

class _RegisterSchoolScreenState extends State<RegisterSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akun admin sudah dibuat. Simpan data berikut sebelum melanjutkan.',
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    'Email\n'
                    '${map['admin_email']}\n\n'
                    'Password awal\n'
                    '${map['initial_password']}',
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Password awal hanya ditampilkan pada tahap ini.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Sudah Disimpan'),
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/login');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Daftarkan Sekolah'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mulai menggunakan E-Absensi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi informasi dasar sekolah. Akun admin akan dibuat secara otomatis.',
                    ),
                    const SizedBox(height: 24),
                    AppPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionTitle(title: 'Informasi sekolah'),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _schoolController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nama Sekolah',
                              prefixIcon: Icon(Icons.apartment_rounded),
                            ),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _adminController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nama Admin',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _entryController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              labelText: 'Jam Masuk',
                              hintText: '07:00',
                              prefixIcon: Icon(Icons.schedule_rounded),
                            ),
                            validator: (value) {
                              final required = _requiredValidator(value);

                              if (required != null) {
                                return required;
                              }

                              final pattern = RegExp(r'^\d{2}:\d{2}$');

                              if (!pattern.hasMatch(value!.trim())) {
                                return 'Gunakan format HH:mm';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Email Admin',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) {
                              final required = _requiredValidator(value);

                              if (required != null) {
                                return required;
                              }

                              if (!value!.contains('@')) {
                                return 'Format email tidak valid';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AppPanel(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 21,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sekolah mendapatkan masa uji coba 7 hari setelah pendaftaran berhasil.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar Sekolah'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
