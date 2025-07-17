import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditTaskPage extends StatefulWidget {
  final String projectId;
  final String taskId;

  const EditTaskPage({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  final List<String> _selectedWorkerIds = [];

  late String companyId;
  bool _loading = true;
  bool _deleting = false;
  String _status = 'todo'; // default fallback

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
    _loadTask();
  }

  Future<void> _loadTask() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .collection('tasks')
            .doc(widget.taskId)
            .get();

    final data = doc.data();
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      _costController.text = (data['estimatedCost'] ?? '').toString();
      _status = data['status'] ?? 'todo';
      final workers = List<String>.from(data['assignedWorkerIds'] ?? []);
      _selectedWorkerIds.addAll(workers);
    }

    setState(() => _loading = false);
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
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .update(taskData);

    setState(() => _loading = false);

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text(
              'Are you sure you want to delete this task? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .delete();

    setState(() => _deleting = false);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleting ? null : _deleteTask,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _deleting
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
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
                            value: 'blocked',
                            child: Text('Blocked'),
                          ),
                          DropdownMenuItem(value: 'done', child: Text('Done')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Assigned Workers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _WorkerSelector(
                        key: ValueKey(_selectedWorkerIds.join(',')),
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
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
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
    super.key,
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

        final selected = List<String>.from(selectedIds);
        final workers = snapshot.data!.docs;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              workers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final workerName = data['name'] ?? 'Unnamed';
                final workerId = doc.id;
                final workerEmail = data['email'] ?? '';
                final isSelected = selected.contains(workerId);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: isSelected ? 5 : 2,
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  child: CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    value: isSelected,
                    title: Text(
                      workerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      workerEmail,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    secondary: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        workerName.isNotEmpty
                            ? workerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    onChanged: (checked) {
                      final updated = List<String>.from(selected);
                      if (checked == true && !updated.contains(workerId)) {
                        updated.add(workerId);
                      } else {
                        updated.remove(workerId);
                      }
                      onChanged(updated);
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
