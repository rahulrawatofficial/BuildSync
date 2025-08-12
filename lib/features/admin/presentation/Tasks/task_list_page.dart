import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/features/admin/presentation/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class TaskListPage extends StatefulWidget {
  final String? initialProjectId; // For preselected project

  const TaskListPage({super.key, this.initialProjectId});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    selectedProjectId = widget.initialProjectId;
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;
    if (companyId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Company ID not found. Please contact administrator.'),
        ),
      );
    }

    return Scaffold(
      drawer: const AdminDrawer(selectedRoute: '/task-list'),
      appBar: AppBar(title: const Text('Project Tasks')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProjectDropdown(
              companyId: companyId,
              value: selectedProjectId,
              onChanged: (projectId) {
                setState(
                  () =>
                      selectedProjectId = projectId.isEmpty ? null : projectId,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TaskSummary(companyId: companyId, projectId: selectedProjectId),
          const Divider(),
          Expanded(
            child: _TaskList(
              companyId: companyId,
              projectId: selectedProjectId,
            ),
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

class TaskSummary extends StatelessWidget {
  final String companyId;
  final String? projectId;

  const TaskSummary({super.key, required this.companyId, this.projectId});

  @override
  Widget build(BuildContext context) {
    final tasksQuery =
        projectId != null
            ? FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('projects')
                .doc(projectId!)
                .collection('tasks')
            : FirebaseFirestore.instance
                .collectionGroup('tasks')
                .where('companyId', isEqualTo: companyId);

    return StreamBuilder<QuerySnapshot>(
      stream: tasksQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final tasks =
            snapshot.data!.docs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList();
        final counts = {
          'Todo': tasks.where((t) => t['status'] == 'todo').length,
          'Active': tasks.where((t) => t['status'] == 'active').length,
          'Blocked': tasks.where((t) => t['status'] == 'blocked').length,
          'Done': tasks.where((t) => t['status'] == 'done').length,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                counts.entries.map((entry) {
                  final color = _statusColor(entry.key.toLowerCase());
                  return Column(
                    children: [
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        entry.key,
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey;
      case 'active':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'done':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

class _TaskList extends StatelessWidget {
  final String companyId;
  final String? projectId;

  const _TaskList({required this.companyId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final taskStream =
        projectId != null
            ? FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('projects')
                .doc(projectId!)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collectionGroup('tasks')
                .where('companyId', isEqualTo: companyId)
                .orderBy('createdAt', descending: true)
                .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks found'));
        }

        final tasks = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final taskDoc = tasks[index];
            final task = taskDoc.data() as Map<String, dynamic>;
            final taskId = taskDoc.id;
            final parentProjectId =
                taskDoc.reference.parent.parent?.id; // For edit navigation

            final title = task['title'] ?? 'Untitled Task';
            final description = task['description'] ?? '';
            final estimatedCost = task['estimatedCost'];
            final status = task['status'] ?? 'Todo';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusChip(status),
                        if (estimatedCost != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Est. \$${estimatedCost.toString()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (parentProjectId != null) {
                    context.push('/edit-task/$parentProjectId/$taskId');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _capitalize(status),
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return Colors.grey;
      case 'active':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return Icons.circle_outlined;
      case 'active':
        return Icons.play_arrow;
      case 'blocked':
        return Icons.block;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.circle_outlined;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
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
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final projects = snapshot.data!.docs;

        final items = [
          const DropdownMenuItem(
            value: '',
            child: Row(
              children: [
                Icon(Icons.layers, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('All Projects'),
              ],
            ),
          ),
          ...projects.map((doc) {
            final project = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Row(
                children: [
                  const Icon(Icons.folder, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(project['title'] ?? 'Untitled'),
                ],
              ),
            );
          }),
        ];

        return DropdownButtonFormField<String>(
          value: value ?? '',
          decoration: const InputDecoration(
            labelText: 'Filter by Project',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items,
          onChanged: (selected) => onChanged(selected ?? ''),
        );
      },
    );
  }
}
