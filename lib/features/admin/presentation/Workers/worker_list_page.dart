import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final companyId = AppSessionManager().companyId;
    return Scaffold(
      appBar: AppBar(title: const Text('Team Members')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('companies')
                  .doc(companyId) // pass the current user's companyId here
                  .collection('users')
                  .where('role', whereIn: ['worker', 'supervisor'])
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No team members found.'));
            }

            final workers = snapshot.data!.docs;

            return ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final user = workers[index].data() as Map<String, dynamic>;
                final name = user['name'] ?? 'Unnamed';
                final role = user['role'] ?? '';
                final email = user['email'] ?? '';
                final phone = user['phone'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          role == 'supervisor' ? Colors.indigo : Colors.green,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role: ${role.toUpperCase()}'),
                        if (email.isNotEmpty) Text('Email: $email'),
                        if (phone.isNotEmpty) Text('Phone: $phone'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final workerId = workers[index].id;
                      final workerData =
                          workers[index].data() as Map<String, dynamic>;

                      context.push(
                        '/edit-worker',
                        extra: {'workerId': workerId, 'workerData': workerData},
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-worker'),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
