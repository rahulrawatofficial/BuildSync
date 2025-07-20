import 'dart:math';

import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<Map<String, dynamic>> _fetchDashboardData(String companyId) async {
    final firestore = FirebaseFirestore.instance;

    // Ongoing projects
    final projectsSnapshot =
        await firestore
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .where('status', isNotEqualTo: 'completed')
            .get();

    // Count workers (users table with role 'worker')
    final workersSnapshot =
        await firestore
            .collection('companies')
            .doc(companyId)
            .collection('users')
            .where('role', isEqualTo: 'worker')
            .get();

    // Pending tasks and deadlines for this week
    int taskCount = 0;
    int upcomingDeadlines = 0;

    DateTime now = DateTime.now();
    DateTime weekEnd = now.add(Duration(days: 7));

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

      for (var taskDoc in tasksSnapshot.docs) {
        final task = taskDoc.data();
        taskCount++;

        if (task.containsKey('endDate') && task['endDate'] != null) {
          final dueDate = DateTime.tryParse(task['endDate']);
          if (dueDate != null &&
              dueDate.isAfter(now) &&
              dueDate.isBefore(weekEnd)) {
            upcomingDeadlines++;
          }
        }
      }
    }

    return {
      'ongoingProjects': projectsSnapshot.docs.length,
      'pendingTasks': taskCount,
      'workers': workersSnapshot.docs.length,
      'upcomingDeadlines': upcomingDeadlines,
    };
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId!;
    final _random = Random();
    Color _randomColor() {
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.redAccent,
        Colors.teal,
      ];
      return colors[_random.nextInt(colors.length)];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -------------------- SUMMARY CARDS --------------------
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchDashboardData(companyId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Pending Tasks',
                          count: data['pendingTasks'],
                          color: Colors.orangeAccent,
                          icon: Icons.task_alt,
                        ),
                        _buildSummaryCard(
                          title: 'Ongoing Projects',
                          count: data['ongoingProjects'],
                          color: Colors.blueAccent,
                          icon: Icons.work_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Workers',
                          count: data['workers'],
                          color: Colors.green,
                          icon: Icons.people,
                        ),
                        _buildSummaryCard(
                          title: 'Deadlines',
                          count: data['upcomingDeadlines'],
                          color: Colors.redAccent,
                          icon: Icons.calendar_today,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            /// -------------------- ONGOING PROJECTS --------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ongoing Projects',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/project-list'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('companies')
                      .doc(companyId)
                      .collection('projects')
                      .where('status', isNotEqualTo: 'completed')
                      .limit(3)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No ongoing projects');
                }

                final projects = snapshot.data!.docs;

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final doc = projects[index];
                    final project = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/edit-project/${doc.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ---- Icon with Random Color ----
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _randomColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.work_outline,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),

                              /// ---- Title & Address ----
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            project['address'] ?? 'No Address',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// ---- Status Chip ----
                              Align(
                                alignment: Alignment.center,
                                child: Chip(
                                  label: Text(
                                    (project['status'] ?? 'active')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _statusColor(
                                    project['status'],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
