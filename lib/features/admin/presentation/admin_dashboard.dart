import 'package:buildsync/core/config/app_setion_manager.dart';
// import 'package:buildsync/features/admin/presentation/Project/project_card.dart';
import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<Map<String, int>> _fetchCounts(String companyId) async {
    final firestore = FirebaseFirestore.instance;

    // Fetch ongoing projects
    final projectsSnapshot =
        await firestore
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .where('status', isNotEqualTo: 'completed')
            .get();

    int ongoingProjectsCount = projectsSnapshot.docs.length;
    int taskCount = 0;

    // For each ongoing project, fetch tasks that are not completed
    for (var projectDoc in projectsSnapshot.docs) {
      final tasksSnapshot =
          await firestore
              .collection('companies')
              .doc(companyId)
              .collection('projects')
              .doc(projectDoc.id)
              .collection('tasks')
              .where('status', isNotEqualTo: 'done')
              .get();

      taskCount += tasksSnapshot.docs.length;
    }

    return {'ongoingProjects': ongoingProjectsCount, 'pendingTasks': taskCount};
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -------------------- TOP SUMMARY CARDS --------------------
            FutureBuilder<Map<String, int>>(
              future: _fetchCounts(companyId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                int ongoingProjects = data['ongoingProjects']!;
                int pendingTasks = data['pendingTasks']!;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCard(
                      title: 'Pending Tasks',
                      count: pendingTasks,
                      color: Colors.orangeAccent,
                      icon: Icons.task_alt,
                    ),
                    _buildSummaryCard(
                      title: 'Ongoing Projects',
                      count: ongoingProjects,
                      color: Colors.blueAccent,
                      icon: Icons.work_outline,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            /// -------------------- PROJECT LIST --------------------
            const Text(
              'Projects',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('companies')
                      .doc(companyId)
                      .collection('projects')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No projects available'));
                }

                final projects = snapshot.data!.docs;

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final doc = projects[index];
                    final project = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          project['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(project['address'] ?? 'No Address'),
                        trailing: Chip(
                          label: Text(project['status'] ?? 'active'),
                          backgroundColor: _statusColor(project['status']),
                        ),
                        onTap: () {
                          context.push('/edit-project/${doc.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-project'),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'active':
        return Colors.blueAccent;
      default:
        return Colors.grey.shade300;
    }
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String? userName = AppSessionManager().name;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.asset("assets/images/adp.png"),
                ),
                const SizedBox(width: 20),
                Text(
                  userName ?? 'Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.green),
            title: const Text('Dashboard'),
            // onTap: () => context.go('/admin'),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.amber),
            title: const Text('Workers'),
            onTap: () => context.push('/worker-list'),
          ),
          ListTile(
            leading: const Icon(Icons.task, color: Colors.purple),
            title: const Text('Tasks'),
            onTap: () => context.push('/task-list'),
          ),
          ListTile(
            leading: const Icon(
              Icons.monetization_on_outlined,
              color: Colors.brown,
            ),
            title: const Text('Expenses'),
            onTap: () => context.push('/expense-list'),
          ),
          ListTile(
            leading: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.lightGreen,
            ),
            title: const Text('Reports'),
            onTap: () => context.push('/reports-list'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AuthCubit>().signOut();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
