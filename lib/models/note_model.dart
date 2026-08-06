class NoteModel {
  final String id;
  final String title;
  final String description;
  final String subjectCode;
  final String subjectName;
  final String semester;
  final String fileUrl;
  final String fileName;
  final String fileSize;
  final String uploadedBy;
  final String uploaderRole;
  final DateTime uploadedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectCode,
    required this.subjectName,
    required this.semester,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploaderRole,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'semester': semester,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploaderRole': uploaderRole,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      semester: map['semester'] ?? 'Semester 1',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? '0 KB',
      uploadedBy: map['uploadedBy'] ?? '',
      uploaderRole: map['uploaderRole'] ?? 'Faculty',
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'])
          : DateTime.now(),
    );
  }
}
