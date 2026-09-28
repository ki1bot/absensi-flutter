import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/api/api_client.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() {
    return _CreateStudentScreenState();
  }
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();

  final _nis = TextEditingController();
  final _name = TextEditingController();
  final _className = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _guardianPhone = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _api.close();
    _nis.dispose();
    _name.dispose();
    _className.dispose();
    _guardianName.dispose();
    _guardianEmail.dispose();
    _guardianPhone.dispose();

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
      final response = await _api.post(
        '/api/v1/students',
        body: {
          'nis': _nis.text.trim(),
          'name': _name.text.trim(),
          'class_name': _className.text.trim(),
          'guardian_name': _guardianName.text.trim(),
          'guardian_email': _guardianEmail.text.trim(),
          'guardian_phone': _guardianPhone.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      final map = Map<String, dynamic>.from(response);

      final password = map['parent_initial_password']?.toString();

      if (password != null && password.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Akun Orang Tua Dibuat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simpan password awal berikut sebelum menutup halaman.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    password,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Sudah Disimpan'),
                ),
              ],
            );
          },
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool required = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label wajib diisi';
                }

                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Siswa')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SectionTitle(
                title: 'Data siswa',
                subtitle: 'Informasi utama siswa yang akan didaftarkan.',
              ),
              const SizedBox(height: 14),
              AppPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _field(
                      controller: _nis,
                      label: 'NIS',
                      icon: Icons.badge_outlined,
                      required: true,
                    ),
                    _field(
                      controller: _name,
                      label: 'Nama Siswa',
                      icon: Icons.person_outline,
                      required: true,
                    ),
                    _field(
                      controller: _className,
                      label: 'Kelas',
                      hint: 'Contoh: XII RPL 1',
                      icon: Icons.class_outlined,
                      required: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const SectionTitle(
                title: 'Data orang tua',
                subtitle: 'Digunakan untuk akun orang tua dan informasi siswa.',
              ),
              const SizedBox(height: 14),
              AppPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _field(
                      controller: _guardianName,
                      label: 'Nama Orang Tua',
                      icon: Icons.supervisor_account_outlined,
                    ),
                    _field(
                      controller: _guardianEmail,
                      label: 'Email Orang Tua',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.mail_outline,
                    ),
                    _field(
                      controller: _guardianPhone,
                      label: 'No. HP Orang Tua',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Siswa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
