class AttendanceModel {
  final String id;
  final String subjectCode;
  final String semester;
  final DateTime date;
  final List<String> presentStudentIds;
  final List<String> absentStudentIds;
  final String facultyId;
  final String facultyName;

  AttendanceModel({
    required this.id,
    required this.subjectCode,
    required this.semester,
    required this.date,
    required this.presentStudentIds,
    required this.absentStudentIds,
    required this.facultyId,
    required this.facultyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectCode': subjectCode,
      'semester': semester,
      'date': date.toIso8601String(),
      'presentStudentIds': presentStudentIds,
      'absentStudentIds': absentStudentIds,
      'facultyId': facultyId,
      'facultyName': facultyName,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      subjectCode: map['subjectCode'] ?? '',
      semester: map['semester'] ?? 'Semester 1',
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      presentStudentIds: List<String>.from(map['presentStudentIds'] ?? []),
      absentStudentIds: List<String>.from(map['absentStudentIds'] ?? []),
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
    );
  }
}
