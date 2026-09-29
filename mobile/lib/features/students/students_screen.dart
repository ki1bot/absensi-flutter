import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/widgets.dart';
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
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final search = Uri.encodeQueryComponent(_searchController.text.trim());

      final result = await _api.get('/api/v1/students?search=$search');

      if (mounted) {
        setState(() {
          _students = result as List<dynamic>;
        });
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

  Future<void> _openCreate() async {
    final changed = await context.push<bool>('/students/create');

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _openStudent(int id) async {
    await context.push('/students/$id');

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Data Siswa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _load();
              },
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Cari nama, NIS, atau kelas',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {});

                          _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _searchController.text.trim().isEmpty
                        ? 'Semua siswa'
                        : 'Hasil pencarian',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${_students.length} data',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Data siswa belum ada',
                    message: 'Tambahkan siswa baru atau coba kata pencarian lainnya.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: _students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final student = Map<String, dynamic>.from(
                          _students[index],
                        );

                        final name = student['name'].toString();

                        final initial = name.isEmpty
                            ? '?'
                            : name[0].toUpperCase();

                        return AppPanel(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            onTap: () {
                              _openStudent(student['id'] as int);
                            },
                            minTileHeight: 74,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            leading: CircleAvatar(
                              radius: 21,
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.onPrimaryContainer,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${student['class_name']} · NIS ${student['nis']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
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
