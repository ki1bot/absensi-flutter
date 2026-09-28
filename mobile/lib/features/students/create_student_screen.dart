import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() {
    return _CreateStudentScreenState();
  }
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
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
    setState(() => _loading = true);

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
          builder: (context) {
            return AlertDialog(
              title: const Text('Akun Orang Tua'),
              content: SelectableText(
                'Password awal orang tua:\n'
                '$password\n\n'
                'Simpan password ini.',
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
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
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Siswa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_nis, 'NIS'),
          _field(_name, 'Nama Siswa'),
          _field(_className, 'Kelas'),
          _field(_guardianName, 'Nama Orang Tua'),
          _field(
            _guardianEmail,
            'Email Orang Tua',
            keyboardType: TextInputType.emailAddress,
          ),
          _field(
            _guardianPhone,
            'No. HP Orang Tua',
            keyboardType: TextInputType.phone,
          ),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
