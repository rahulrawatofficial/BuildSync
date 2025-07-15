import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTaskPage extends StatefulWidget {
  final String projectId;

  const AddTaskPage({super.key, required this.projectId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  final List<String> _selectedWorkerIds = [];

  late String companyId;
  String _status = 'todo'; // default status

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'estimatedCost': double.tryParse(_costController.text.trim()) ?? 0,
      'assignedWorkerIds': _selectedWorkerIds,
      'status': _status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .add(taskData);

    setState(() => _loading = false);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Task name is required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Cost',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'todo', child: Text('To Do')),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'Blocked',
                            child: Text('Blocked'),
                          ),
                          DropdownMenuItem(value: 'Done', child: Text('Done')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Assign Workers',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _WorkerSelector(
                        companyId: companyId,
                        selectedIds: _selectedWorkerIds,
                        onChanged: (newList) {
                          setState(() {
                            _selectedWorkerIds
                              ..clear()
                              ..addAll(newList);
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check),
                          label: const Text('Create Task'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _WorkerSelector extends StatelessWidget {
  final String companyId;
  final List<String> selectedIds;
  final void Function(List<String>) onChanged;

  const _WorkerSelector({
    required this.companyId,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('users')
              .where('role', isEqualTo: 'worker')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No workers found');
        }

        final workers = snapshot.data!.docs;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              workers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final workerName = data['name'] ?? 'Unnamed';
                final workerId = doc.id;

                final isSelected = selectedIds.contains(workerId);

                return CheckboxListTile(
                  title: Text(workerName),
                  subtitle: Text(data['email'] ?? ''),
                  value: isSelected,
                  onChanged: (checked) {
                    final updated = [...selectedIds];
                    if (checked == true) {
                      updated.add(workerId);
                    } else {
                      updated.remove(workerId);
                    }
                    onChanged(updated);
                  },
                );
              }).toList(),
        );
      },
    );
  }
}
