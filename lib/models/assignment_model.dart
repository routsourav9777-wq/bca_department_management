class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String subjectCode;
  final String semester;
  final DateTime dueDate;
  final String? attachmentUrl;
  final String createdBy;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectCode,
    required this.semester,
    required this.dueDate,
    this.attachmentUrl,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectCode': subjectCode,
      'semester': semester,
      'dueDate': dueDate.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      semester: map['semester'] ?? 'Semester 1',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now().add(const Duration(days: 7)),
      attachmentUrl: map['attachmentUrl'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
