import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/features/admin/presentation/Project/project_card.dart';
import 'package:buildsync/global/blocs/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AdminDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId) // pass the current user's companyId here
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
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final doc = projects[index];
              final project = doc.data() as Map<String, dynamic>;

              return ProjectCard(
                id: doc.id,
                title: project['title'] ?? 'No Title',
                address: project['address'] ?? 'No Address',
                startDate: project['startDate'],
                status: project['status'] ?? 'active',
                onTap: () {
                  context.push('/edit-project/${doc.id}');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-project'),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
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
            decoration: BoxDecoration(color: Colors.blue),
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
                SizedBox(width: 20),
                Text(
                  userName!,
                  style: TextStyle(color: Colors.white, fontSize: 24),
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
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: const Text('Settings'),
            // onTap: () => context.go('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Sign out using AuthCubit
              await context.read<AuthCubit>().signOut();

              // Navigate to login screen and clear navigation stack
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
