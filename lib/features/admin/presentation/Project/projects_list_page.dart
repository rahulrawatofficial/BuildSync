import 'dart:math';
import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ProjectsListPage extends StatelessWidget {
  const ProjectsListPage({super.key});

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade600; // Deep forest green
      case 'active':
        return Colors.teal.shade400; // Teal for progress
      case 'pending':
        return Colors.amber.shade600; // Warm amber for pending
      default:
        return Colors.grey.shade500; // Neutral grey
    }
  }

  Color _randomColor() {
    final colors = [
      Colors.green.shade600, // Forest green
      Colors.teal.shade400, // Teal
      Colors.orange.shade600, // Warm orange
      Colors.purple.shade400, // Modern purple
      Colors.red.shade400, // Muted red
      Colors.brown.shade400, // Earthy brown
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;

    return Scaffold(
      appBar: AppBar(title: const Text('All Projects')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('companies')
                  .doc(companyId)
                  .collection('projects')
                  .orderBy('createdAt', descending: true)
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
                          /// Project Icon with random color
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

                          /// Title & Address
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

                          /// Status Chip
                          Align(
                            alignment: Alignment.center,
                            child: Chip(
                              label: Text(
                                (project['status'] ?? 'active').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _statusColor(project['status']),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-project'),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }
}
