import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user
  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // Create or update user
  Future<void> createUser(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Create project
  Future<void> createProject(Map<String, dynamic> data) {
    return _db.collection('projects').add(data);
  }

  // Get projects by owner
  Stream<QuerySnapshot> getOwnerProjects(String ownerId) {
    return _db
        .collection('projects')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots();
  }

  // Add task to a project
  Future<void> addTask(String projectId, Map<String, dynamic> taskData) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add(taskData);
  }

  // Log daily work
  Future<void> logDailyWork(String projectId, Map<String, dynamic> logData) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('dailyLogs')
        .add(logData);
  }
}
