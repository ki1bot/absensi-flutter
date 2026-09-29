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
                    'Simpan password awal berikut. Password ini diperlukan untuk login pertama.',
                  ),
                  const SizedBox(height: 18),
                  AppPanel(
                    child: SelectableText(
                      password,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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

  String? _required(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }

    return null;
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
              const PageIntro(
                title: 'Data siswa baru',
                subtitle: 'Masukkan data utama siswa terlebih dahulu, kemudian data orang tua jika diperlukan.',
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Informasi siswa'),
              const SizedBox(height: 12),
              AppPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nis,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'NIS',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        return _required('NIS', value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Siswa',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        return _required('Nama Siswa', value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _className,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        hintText: 'Contoh: XII RPL 1',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      validator: (value) {
                        return _required('Kelas', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const SectionTitle(
                title: 'Data orang tua',
                subtitle: 'Opsional apabila belum ingin membuat akun orang tua',
              ),
              const SizedBox(height: 12),
              AppPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _guardianName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Orang Tua',
                        prefixIcon: Icon(Icons.supervisor_account_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _guardianEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Orang Tua',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !value.contains('@')) {
                          return 'Format email tidak valid';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _guardianPhone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'No. HP Orang Tua',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
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
                    : const Text('Simpan Siswa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
