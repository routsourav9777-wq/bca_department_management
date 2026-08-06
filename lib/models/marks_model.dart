class MarksModel {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNo;
  final String subjectCode;
  final String subjectName;
  final String semester;
  final double markObtained;
  final double maxMarks;
  final String examType; // Mid-Sem 1, Mid-Sem 2, Internal
  final String facultyId;
  final DateTime uploadedAt;

  MarksModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
    required this.markObtained,
    this.maxMarks = 20.0,
    required this.examType,
    required this.facultyId,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'rollNo': rollNo,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'semester': semester,
      'markObtained': markObtained,
      'maxMarks': maxMarks,
      'examType': examType,
      'facultyId': facultyId,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory MarksModel.fromMap(Map<String, dynamic> map, String id) {
    return MarksModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      rollNo: map['rollNo'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      semester: map['semester'] ?? 'Semester 1',
      markObtained: (map['markObtained'] as num?)?.toDouble() ?? 0.0,
      maxMarks: (map['maxMarks'] as num?)?.toDouble() ?? 20.0,
      examType: map['examType'] ?? 'Internal Test 1',
      facultyId: map['facultyId'] ?? '',
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'])
          : DateTime.now(),
    );
  }
}
