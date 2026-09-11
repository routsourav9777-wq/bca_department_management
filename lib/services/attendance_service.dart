import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection('attendance');

  // ============================================================
  // DOCUMENT ID
  // ============================================================

  String _documentId({
    required String studentUid,
    required String subjectId,
    required DateTime date,
  }) {
    return '${studentUid}_${subjectId}_'
        '${date.year}_'
        '${date.month.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MARK PRESENT
  //
  // SAME STUDENT
  // SAME SUBJECT
  // SAME DAY
  // = ONLY ONE P
  // ============================================================

  Future<AttendanceResult> markPresent({
    required String studentUid,
    required String rollNo,
    required String studentName,
    required String semester,
    required String subjectId,
    required String subjectName,
    DateTime? date,
  }) async {
    final DateTime now = date ?? DateTime.now();

    final DateTime attendanceDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final String documentId = _documentId(
      studentUid: studentUid,
      subjectId: subjectId,
      date: attendanceDate,
    );

    final DocumentReference<Map<String, dynamic>> ref =
        _attendance.doc(documentId);

    final String day = attendanceDate.day.toString();

    bool alreadyPresent = false;

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);

        if (snapshot.exists) {
          final Map<String, dynamic>? data = snapshot.data();

          final dynamic rawDays = data?['days'];

          if (rawDays is Map) {
            final dynamic todayStatus = rawDays[day];

            if (todayStatus?.toString().toUpperCase() == 'P') {
              alreadyPresent = true;
              return;
            }
          }
        }

        transaction.set(
          ref,
          {
            'studentUid': studentUid,
            'rollNo': rollNo,
            'studentName': studentName,
            'semester': semester,
            'subjectId': subjectId,
            'subjectName': subjectName,
            'year': attendanceDate.year,
            'month': attendanceDate.month,
            'days.$day': 'P',
            'updatedAt': FieldValue.serverTimestamp(),
            'lastAttendanceDate': Timestamp.fromDate(
              attendanceDate,
            ),
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );

    if (alreadyPresent) {
      return AttendanceResult(
        success: false,
        alreadyPresent: true,
        message: 'Attendance already marked for today.',
      );
    }

    return AttendanceResult(
      success: true,
      alreadyPresent: false,
      message: 'Attendance marked successfully.',
    );
  }

  // ============================================================
  // GET TODAY STATUS
  // ============================================================

  Future<bool> isPresentToday({
    required String studentUid,
    required String subjectId,
    DateTime? date,
  }) async {
    final DateTime now = date ?? DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final String documentId = _documentId(
      studentUid: studentUid,
      subjectId: subjectId,
      date: today,
    );

    final snapshot = await _attendance.doc(documentId).get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    if (data == null) {
      return false;
    }

    final dynamic days = data['days'];

    if (days is! Map) {
      return false;
    }

    final String day = today.day.toString();

    return days[day] == 'P';
  }

  // ============================================================
  // MONTHLY ATTENDANCE
  // ============================================================

  Future<Map<String, String>> getMonthlyAttendance({
    required String studentUid,
    required String subjectId,
    required int year,
    required int month,
  }) async {
    final String documentId = '${studentUid}_${subjectId}_'
        '${year}_'
        '${month.toString().padLeft(2, '0')}';

    final snapshot = await _attendance.doc(documentId).get();

    if (!snapshot.exists) {
      return {};
    }

    final data = snapshot.data();

    if (data == null) {
      return {};
    }

    final dynamic rawDays = data['days'];

    if (rawDays is! Map) {
      return {};
    }

    final Map<String, String> result = {};

    rawDays.forEach(
      (key, value) {
        result[key.toString()] = value.toString();
      },
    );

    return result;
  }

  // ============================================================
  // PRESENT COUNT
  // ============================================================

  Future<int> getPresentCount({
    required String studentUid,
    required String subjectId,
    required int year,
    required int month,
  }) async {
    final days = await getMonthlyAttendance(
      studentUid: studentUid,
      subjectId: subjectId,
      year: year,
      month: month,
    );

    return days.values
        .where(
          (value) => value.toUpperCase() == 'P',
        )
        .length;
  }

  // ============================================================
  // ABSENT COUNT
  // ============================================================

  Future<int> getAbsentCount({
    required String studentUid,
    required String subjectId,
    required int year,
    required int month,
  }) async {
    final days = await getMonthlyAttendance(
      studentUid: studentUid,
      subjectId: subjectId,
      year: year,
      month: month,
    );

    return days.values
        .where(
          (value) => value.toUpperCase() == 'A',
        )
        .length;
  }
}

// ============================================================
// RESULT
// ============================================================

class AttendanceResult {
  final bool success;
  final bool alreadyPresent;
  final String message;

  AttendanceResult({
    required this.success,
    required this.alreadyPresent,
    required this.message,
  });
}
