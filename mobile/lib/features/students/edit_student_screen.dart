import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/api/api_client.dart';

class EditStudentScreen extends StatefulWidget {
  const EditStudentScreen({required this.studentId, super.key});

  final int studentId;

  @override
  State<EditStudentScreen> createState() {
    return _EditStudentScreenState();
  }
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();

  final _nis = TextEditingController();
  final _name = TextEditingController();
  final _className = TextEditingController();

  final _guardianName = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _guardianPhone = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _load();
  }

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

  Future<void> _load() async {
    try {
      final result = await _api.get('/api/v1/students/${widget.studentId}');

      final student = Map<String, dynamic>.from(result);

      _nis.text = student['nis'].toString();
      _name.text = student['name'].toString();
      _className.text = student['class_name'].toString();

      _guardianName.text = student['guardian_name'].toString();
      _guardianEmail.text = student['guardian_email'].toString();
      _guardianPhone.text = student['guardian_phone'].toString();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await _api.put(
        '/api/v1/students/${widget.studentId}',
        body: {
          'nis': _nis.text.trim(),
          'name': _name.text.trim(),
          'class_name': _className.text.trim(),
          'guardian_name': _guardianName.text.trim(),
          'guardian_email': _guardianEmail.text.trim(),
          'guardian_phone': _guardianPhone.text.trim(),
        },
      );

      final map = Map<String, dynamic>.from(result);

      final initialPassword = map['parent_initial_password']?.toString();

      if (initialPassword != null && initialPassword.isNotEmpty && mounted) {
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
                    'Simpan password awal berikut untuk login akun orang tua.',
                  ),
                  const SizedBox(height: 18),
                  AppPanel(
                    child: SelectableText(
                      initialPassword,
                      style: Theme.of(context).textTheme.titleLarge,
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
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
          _saving = false;
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
      appBar: AppBar(title: const Text('Edit Data Siswa')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const PageIntro(
                    title: 'Perbarui data siswa',
                    subtitle: 'Pastikan informasi yang diubah sudah sesuai sebelum disimpan.',
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
                    subtitle: 'Kosongkan email apabila siswa tidak menggunakan akun orang tua',
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
                    onPressed: _saving ? null : _save,
                    child: _saving
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
                ],
              ),
            ),
    );
  }
}
