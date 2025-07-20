import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _dueDateController = TextEditingController();

  final List<String> _selectedWorkerIds = [];

  late String companyId;
  bool _loading = true;
  bool _deleting = false;
  String _status = 'todo'; // default fallback
  DateTime? _dueDate;

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

      if (data['dueDate'] != null) {
        _dueDate = (data['dueDate'] as Timestamp).toDate();
        _dueDateController.text =
            '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
      }

      final workers = List<String>.from(data['assignedWorkerIds'] ?? []);
      _selectedWorkerIds.addAll(workers);
    }

    setState(() => _loading = false);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
        _dueDateController.text =
            '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
      });
    }
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
      'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'companyId': companyId,
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
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      SizedBox(height: 10),
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
                      GestureDetector(
                        onTap: _pickDueDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dueDateController,
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please select a due date'
                                        : null,
                          ),
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
                      const SizedBox(height: 80), // space for sticky button
                    ],
                  ),
                ),
              ),
      bottomNavigationBar:
          !_loading && !_deleting
              ? Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}

class _WorkerSelector extends StatefulWidget {
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
  State<_WorkerSelector> createState() => _WorkerSelectorState();
}

class _WorkerSelectorState extends State<_WorkerSelector> {
  late List<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List<String>.from(widget.selectedIds);
  }

  void _toggleSelection(String workerId) {
    setState(() {
      if (_localSelected.contains(workerId)) {
        _localSelected.remove(workerId);
      } else {
        _localSelected.add(workerId);
      }
      widget.onChanged(_localSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final doc = workers[index];
            final data = doc.data() as Map<String, dynamic>;
            final workerId = doc.id;
            final workerName = data['name'] ?? 'Unnamed';
            final workerEmail = data['email'] ?? '';
            final isSelected = _localSelected.contains(workerId);

            return GestureDetector(
              onTap: () => _toggleSelection(workerId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.green.withOpacity(0.12)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: 1.3,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          isSelected ? Colors.green : Colors.blueAccent,
                      child: Text(
                        workerName.isNotEmpty
                            ? workerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  isSelected
                                      ? Colors.green.shade900
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workerEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
