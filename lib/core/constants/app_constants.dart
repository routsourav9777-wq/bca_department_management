class AppConstants {
  static const String collegeName = 'Salipur Autonomous College';
  static const String departmentName = 'BCA Department';
  static const String appTitle = 'BCA Dept Management System';

  // Roles
  static const String roleHOD = 'HOD';
  static const String roleFaculty = 'Faculty';
  static const String roleStudent = 'Student';

  // Statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Semesters
  static const List<String> semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String subjectsCollection = 'subjects';
  static const String noticesCollection = 'notices';
  static const String notesCollection = 'notes';
  static const String assignmentsCollection = 'assignments';
  static const String submissionsCollection = 'submissions';
  static const String attendanceCollection = 'attendance';
  static const String marksCollection = 'marks';
  static const String notificationsCollection = 'notifications';
}
