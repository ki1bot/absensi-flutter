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
                  const Text('Simpan password awal berikut.'),
                  const SizedBox(height: 16),
                  SelectableText(
                    initialPassword,
                    style: Theme.of(context).textTheme.titleLarge,
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label wajib diisi';
          }

          if (label == 'Email Orang Tua' &&
              value != null &&
              value.trim().isNotEmpty &&
              !value.contains('@')) {
            return 'Format email tidak valid';
          }

          return null;
        },
      ),
    );
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
                  const SectionTitle(
                    title: 'Data siswa',
                    subtitle: 'Perbarui informasi utama siswa.',
                  ),
                  const SizedBox(height: 12),
                  AppPanel(
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
                          icon: Icons.person_outline_rounded,
                          required: true,
                        ),
                        _field(
                          controller: _className,
                          label: 'Kelas',
                          icon: Icons.class_outlined,
                          required: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const SectionTitle(
                    title: 'Data orang tua',
                    subtitle: 'Kosongkan email jika tidak menggunakan akun orang tua.',
                  ),
                  const SizedBox(height: 12),
                  AppPanel(
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
                          icon: Icons.mail_outline_rounded,
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
