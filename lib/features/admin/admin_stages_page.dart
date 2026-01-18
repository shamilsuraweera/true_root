import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stages/models/stage.dart';
import '../stages/state/stage_provider.dart';

class AdminStagesPage extends ConsumerStatefulWidget {
  const AdminStagesPage({super.key});

  @override
  ConsumerState<AdminStagesPage> createState() => _AdminStagesPageState();
}

class _AdminStagesPageState extends ConsumerState<AdminStagesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(stageListProvider);
    await ref.read(stageListProvider.future);
  }

  Future<void> _openEditor({Stage? stage}) async {
    final isEditing = stage != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: stage?.name ?? '');
    final sequenceController = TextEditingController(text: stage?.sequence.toString() ?? '');
    bool activeValue = stage?.active ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Stage' : 'Create Stage'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sequenceController,
                        decoration: const InputDecoration(labelText: 'Sequence'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sequence required';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Sequence must be a number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: activeValue,
                        title: const Text('Active'),
                        onChanged: (value) => setState(() {
                          activeValue = value;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final api = ref.read(stagesApiProvider);
    final payload = {
      'name': nameController.text.trim(),
      'sequence': int.parse(sequenceController.text.trim()),
      'active': activeValue,
    };
    try {
      if (isEditing) {
        await api.updateStage(stage.id, payload);
      } else {
        await api.createStage(payload);
      }
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Failed to update stage' : 'Failed to create stage')),
      );
    }
  }

  Future<void> _deleteStage(Stage stage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete stage?'),
          content: Text('Delete ${stage.name}? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    final api = ref.read(stagesApiProvider);
    try {
      await api.deleteStage(stage.id);
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete stage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stageListProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Stages', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add Stage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search stages',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          stagesAsync.when(
            data: (stages) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? stages
                  : stages.where((stage) => stage.name.toLowerCase().contains(query)).toList();
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No stages found')),
                );
              }
              return Column(
                children: [
                  for (final stage in filtered)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(stage.name),
                        subtitle: Text('Sequence ${stage.sequence} • ${stage.active ? 'Active' : 'Inactive'}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditor(stage: stage),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteStage(stage),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Failed to load stages')),
            ),
          ),
        ],
      ),
    );
  }
}
