class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // HOD, Faculty, Student
  final String status; // pending, approved, rejected
  final String? phone;
  final String? rollNo; // For students
  final String? employeeId; // For faculty
  final String? semester; // For students (Semester 1 to 6)
  final String? designation; // For faculty
  final String? profilePicUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'approved',
    this.phone,
    this.rollNo,
    this.employeeId,
    this.semester,
    this.designation,
    this.profilePicUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'phone': phone,
      'rollNo': rollNo,
      'employeeId': employeeId,
      'semester': semester,
      'designation': designation,
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Student',
      status: map['status'] ?? 'approved',
      phone: map['phone'],
      rollNo: map['rollNo'],
      employeeId: map['employeeId'],
      semester: map['semester'],
      designation: map['designation'],
      profilePicUrl: map['profilePicUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
