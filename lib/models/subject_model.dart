class SubjectModel {
  final String id;
  final String code;
  final String name;
  final String semester; // Semester 1 to 6
  final int credits;
  final String assignedFacultyId;
  final String assignedFacultyName;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.semester,
    required this.credits,
    required this.assignedFacultyId,
    required this.assignedFacultyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'semester': semester,
      'credits': credits,
      'assignedFacultyId': assignedFacultyId,
      'assignedFacultyName': assignedFacultyName,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      semester: map['semester'] ?? 'Semester 1',
      credits: map['credits'] ?? 4,
      assignedFacultyId: map['assignedFacultyId'] ?? '',
      assignedFacultyName: map['assignedFacultyName'] ?? '',
    );
  }
}
