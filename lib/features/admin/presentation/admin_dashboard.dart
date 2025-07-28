import 'dart:math';

import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/core/theme/theme_constants.dart';
import 'package:buildsync/features/admin/presentation/Project/project_action_sheet.dart';
import 'package:buildsync/features/admin/presentation/admin_drawer.dart';
import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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
    DateTime weekEnd = now.add(const Duration(days: 7));

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
      drawer: AdminDrawer(selectedRoute: "/home"),
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
                  return _buildShimmerSummaryCards();
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
                      // .limit(3)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerProjectList();
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
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder:
                                (_) => ProjectActionSheet(
                                  projectName:
                                      project['title'] ?? 'Untitled Project',
                                  projectId: doc.id,
                                  onEditProject:
                                      (id) => context.push('/edit-project/$id'),
                                  onAddExpense:
                                      (id) => context.push('/expense-list/$id'),
                                  onAddTask:
                                      (id) => context.push('/task-list/$id'),
                                  onGenerateQuote:
                                      (id) => context.push(
                                        '/quote-list/$companyId/$id',
                                      ),
                                ),
                          );
                        },
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

  /// -------------------- SUMMARY CARDS --------------------
  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              radius: 22,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------- SHIMMER PLACEHOLDERS --------------------
  Widget _buildShimmerSummaryCards() {
    return Column(
      children: [
        Row(children: [_buildShimmerCard(), _buildShimmerCard()]),
        const SizedBox(height: 12),
        Row(children: [_buildShimmerCard(), _buildShimmerCard()]),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Expanded(
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerProjectList() {
    return Column(
      children: List.generate(
        3,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
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
