class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorRole;
  final String? attachmentUrl;
  final String? attachmentName;
  final String targetAudience; // All, Faculty, Students, Semester 1, etc.
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorRole,
    this.attachmentUrl,
    this.attachmentName,
    this.targetAudience = 'All',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorRole': authorRole,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'targetAudience': targetAudience,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? 'HOD BCA',
      authorRole: map['authorRole'] ?? 'HOD',
      attachmentUrl: map['attachmentUrl'],
      attachmentName: map['attachmentName'],
      targetAudience: map['targetAudience'] ?? 'All',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
