import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() {
    return _StudentsScreenState();
  }
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _api = ApiClient();
  final _searchController = TextEditingController();

  List<dynamic> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _api.close();
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final search = Uri.encodeQueryComponent(_searchController.text.trim());

      final result = await _api.get('/api/v1/students?search=$search');

      if (mounted) {
        setState(() {
          _students = result as List<dynamic>;
        });
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
      appBar: AppBar(title: const Text('Data Siswa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await context.push<bool>('/students/create');

          if (changed == true) {
            _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Siswa'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari siswa...',
              leading: const Icon(Icons.search),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final student = Map<String, dynamic>.from(
                          _students[index],
                        );

                        return Card(
                          child: ListTile(
                            onTap: () {
                              context.push(
                                '/students/'
                                '${student['id']}',
                              );
                            },
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(student['name'].toString()),
                            subtitle: Text(
                              '${student['class_name']} • '
                              'NIS ${student['nis']}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
