import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String? selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Tasks')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProjectDropdown(
              companyId: companyId!,
              value: selectedProjectId,
              onChanged: (projectId) {
                setState(() => selectedProjectId = projectId);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          if (selectedProjectId != null)
            Expanded(
              child: _TaskList(
                companyId: companyId,
                projectId: selectedProjectId!,
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Select a project to view tasks')),
            ),
        ],
      ),
      floatingActionButton:
          selectedProjectId != null
              ? FloatingActionButton.extended(
                onPressed: () {
                  context.push('/add-task/${selectedProjectId!}');
                },
                label: const Text('Add Task'),
                icon: const Icon(Icons.add),
              )
              : null,
    );
  }
}

class _ProjectDropdown extends StatelessWidget {
  final String companyId;
  final String? value;
  final void Function(String) onChanged;

  const _ProjectDropdown({
    required this.companyId,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('projects')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No projects available');
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(labelText: 'Select Project'),
          items:
              docs.map((doc) {
                final project = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(project['title'] ?? 'Untitled'),
                );
              }).toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        );
      },
    );
  }
}

class _TaskList extends StatelessWidget {
  final String companyId;
  final String projectId;

  const _TaskList({required this.companyId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('projects')
              .doc(projectId)
              .collection('tasks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks found'));
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          // separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final taskDoc = tasks[index];
            final task = taskDoc.data() as Map<String, dynamic>;
            final taskId = taskDoc.id;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.task_alt, color: Colors.blue),
                ),
                title: Text(
                  task['title'] ?? 'Untitled Task',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      task['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (task['estimatedCost'] != null)
                      Text(
                        'Est. Cost: \$${task['estimatedCost']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(task['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _capitalize(task['status'] ?? 'Todo'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/edit-task/$projectId/$taskId');
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'todo':
        return Colors.grey.shade600;
      case 'active':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper function to capitalize first letter
  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
