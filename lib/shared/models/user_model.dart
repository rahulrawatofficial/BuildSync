class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'admin', 'worker', 'supervisor'
  final List<String> assignedProjects;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.assignedProjects,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'worker',
      assignedProjects: List<String>.from(map['assignedProjects'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'assignedProjects': assignedProjects,
    };
  }
}
