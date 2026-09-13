import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({
    super.key,
  });

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _subjectAttendance = [];

  double _overallPercentage = 0;

  int _overallAttended = 0;
  int _overallTotal = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  // ============================================================
  // LOAD ATTENDANCE
  // ============================================================

  Future<void> _loadAttendance() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // ========================================================
      // CURRENT FIREBASE USER
      // ========================================================

      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please login again.',
        );
      }

      final String studentUid = user.uid;

      debugPrint('==========================================');
      debugPrint('STUDENT ATTENDANCE');
      debugPrint('Student UID: $studentUid');
      debugPrint('==========================================');

      // ========================================================
      // GET STUDENT PROFILE DIRECTLY BY UID
      //
      // students/{uid}
      //
      // This matches production Firestore rules.
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> studentDoc =
          await _firestore.collection('students').doc(studentUid).get();

      if (!studentDoc.exists) {
        throw Exception(
          'Student profile not found.',
        );
      }

      final Map<String, dynamic> student = studentDoc.data() ?? {};

      // ========================================================
      // CHECK STUDENT UID
      // ========================================================

      final String storedUid = student['uid']?.toString().trim() ?? '';

      if (storedUid.isNotEmpty && storedUid != studentUid) {
        throw Exception(
          'Student account verification failed.',
        );
      }

      // ========================================================
      // CHECK ROLE
      // ========================================================

      final String role =
          student['role']?.toString().trim().toLowerCase() ?? '';

      if (role != 'student') {
        throw Exception(
          'This account is not registered as a student.',
        );
      }

      // ========================================================
      // CHECK DEPARTMENT
      // ========================================================

      final String department = student['department']?.toString().trim() ?? '';

      if (department.isEmpty) {
        throw Exception(
          'Student department not found.',
        );
      }

      // ========================================================
      // CHECK STATUS
      // ========================================================

      final String status =
          student['status']?.toString().trim().toLowerCase() ?? '';

      if (status != 'approved' && status != 'active') {
        throw Exception(
          'Student account is not active.',
        );
      }

      // ========================================================
      // SEMESTER
      // ========================================================

      final String semester = student['semester']?.toString().trim() ?? '';

      if (semester.isEmpty) {
        throw Exception(
          'Student semester not found.',
        );
      }

      debugPrint('Department: $department');
      debugPrint('Semester: $semester');
      debugPrint('Status: $status');

      // ========================================================
      // GET ATTENDANCE SESSIONS
      //
      // Your Firestore rules allow students to read
      // attendance_sessions.
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> sessionSnapshot =
          await _firestore.collection('attendance_sessions').get();

      debugPrint(
        'Total attendance sessions: '
        '${sessionSnapshot.docs.length}',
      );

      // ========================================================
      // GET ONLY CURRENT STUDENT ATTENDANCE RECORDS
      //
      // IMPORTANT:
      //
      // We query using:
      //
      // studentUid == current user's UID
      //
      // This matches the Firestore security rule:
      //
      // allow read: if isStudent()
      //   && resource.data.studentUid == request.auth.uid;
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> recordSnapshot =
          await _firestore
              .collection('attendance_records')
              .where(
                'studentUid',
                isEqualTo: studentUid,
              )
              .get();

      debugPrint(
        'Student attendance records: '
        '${recordSnapshot.docs.length}',
      );

      // ========================================================
      // CREATE RECORD LOOKUP
      //
      // sessionId -> attendance record
      // ========================================================

      final Map<String, Map<String, dynamic>> recordMap = {};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> recordDoc
          in recordSnapshot.docs) {
        final Map<String, dynamic> record = recordDoc.data();

        String sessionId = record['sessionId']?.toString().trim() ?? '';

        // ------------------------------------------------------
        // FALLBACK:
        // If sessionId is not stored, use document ID.
        //
        // Expected document ID:
        // sessionId_studentUid
        // ------------------------------------------------------

        if (sessionId.isEmpty) {
          final String documentId = recordDoc.id;

          final String suffix = '_$studentUid';

          if (documentId.endsWith(suffix)) {
            sessionId = documentId.substring(
              0,
              documentId.length - suffix.length,
            );
          }
        }

        if (sessionId.isNotEmpty) {
          recordMap[sessionId] = record;
        }
      }

      // ========================================================
      // SUBJECT MAP
      // ========================================================

      final Map<String, Map<String, dynamic>> subjectMap = {};

      // ========================================================
      // PROCESS SESSIONS
      // ========================================================

      for (final QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc
          in sessionSnapshot.docs) {
        final Map<String, dynamic> session = sessionDoc.data();

        // ------------------------------------------------------
        // SESSION ID
        // ------------------------------------------------------

        final String sessionId =
            session['sessionId']?.toString().trim() ?? sessionDoc.id;

        if (sessionId.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // DEPARTMENT FILTER
        // ------------------------------------------------------

        final String sessionDepartment =
            session['department']?.toString().trim() ?? '';

        if (sessionDepartment.isNotEmpty &&
            sessionDepartment.toLowerCase() != department.toLowerCase()) {
          continue;
        }

        // ------------------------------------------------------
        // SEMESTER FILTER
        // ------------------------------------------------------

        final String sessionSemester =
            session['semester']?.toString().trim() ?? '';

        if (sessionSemester.isNotEmpty &&
            !_sameSemester(
              sessionSemester,
              semester,
            )) {
          continue;
        }

        // ------------------------------------------------------
        // SUBJECT ID
        // ------------------------------------------------------

        final String subjectId = session['subjectId']?.toString().trim() ?? '';

        if (subjectId.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // SUBJECT NAME
        // ------------------------------------------------------

        final String subjectName =
            session['subjectName']?.toString().trim() ?? 'Unknown Subject';

        // ------------------------------------------------------
        // SUBJECT CODE
        // ------------------------------------------------------

        final String subjectCode =
            session['subjectCode']?.toString().trim() ?? '';

        // ======================================================
        // CREATE SUBJECT ENTRY
        // ======================================================

        if (!subjectMap.containsKey(subjectId)) {
          subjectMap[subjectId] = {
            'code': subjectCode.isNotEmpty ? subjectCode : subjectId,
            'name': subjectName,
            'attended': 0,
            'total': 0,
          };
        }

        // ======================================================
        // ONE SESSION = ONE CLASS
        // ======================================================

        subjectMap[subjectId]!['total'] =
            (subjectMap[subjectId]!['total'] as int) + 1;

        // ======================================================
        // CHECK PRESENT
        // ======================================================

        if (recordMap.containsKey(sessionId)) {
          subjectMap[subjectId]!['attended'] =
              (subjectMap[subjectId]!['attended'] as int) + 1;
        }
      }

      // ========================================================
      // CREATE SUBJECT LIST
      // ========================================================

      final List<Map<String, dynamic>> subjects = [];

      int overallAttended = 0;
      int overallTotal = 0;

      for (final Map<String, dynamic> subject in subjectMap.values) {
        final int attended = subject['attended'] as int;

        final int total = subject['total'] as int;

        final double percentage = total > 0 ? (attended / total) * 100 : 0;

        subjects.add({
          'code': subject['code'],
          'name': subject['name'],
          'attended': attended,
          'total': total,
          'pct': percentage,
        });

        overallAttended += attended;
        overallTotal += total;
      }

      // ========================================================
      // SORT
      // ========================================================

      subjects.sort(
        (
          Map<String, dynamic> a,
          Map<String, dynamic> b,
        ) {
          return a['code'].toString().compareTo(
                b['code'].toString(),
              );
        },
      );

      // ========================================================
      // OVERALL PERCENTAGE
      // ========================================================

      final double overallPercentage =
          overallTotal > 0 ? (overallAttended / overallTotal) * 100 : 0;

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint('==========================================');
      debugPrint('APPLICABLE CLASSES: $overallTotal');
      debugPrint('PRESENT: $overallAttended');
      debugPrint(
        'ABSENT: ${overallTotal - overallAttended}',
      );
      debugPrint(
        'PERCENTAGE: $overallPercentage',
      );
      debugPrint('==========================================');

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        _subjectAttendance = subjects;
        _overallAttended = overallAttended;
        _overallTotal = overallTotal;
        _overallPercentage = overallPercentage;
        _loading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Attendance Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.code == 'permission-denied'
            ? 'You do not have permission to view your attendance.'
            : e.message ?? 'Unable to load attendance.';
      });
    } catch (e) {
      debugPrint(
        'Attendance loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;

        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // NORMALIZE SEMESTER
  // ============================================================

  String _normalizeSemester(dynamic value) {
    return value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(
          'semester',
          '',
        )
        .trim();
  }

  // ============================================================
  // SAME SEMESTER
  // ============================================================

  bool _sameSemester(
    String first,
    String second,
  ) {
    return _normalizeSemester(first) == _normalizeSemester(second);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(double percentage) {
    if (percentage >= 85) {
      return 'Excellent Attendance';
    }

    if (percentage >= 75) {
      return 'Good Standing';
    }

    if (percentage >= 65) {
      return 'Attendance Low';
    }

    return 'Critical Attendance';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    }

    if (percentage >= 65) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Attendance Report',
        ),
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_subjectAttendance.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAttendance,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.event_available_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Attendance sessions will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverallCard(),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subject-wise Attendance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ..._subjectAttendance.map(
              (Map<String, dynamic> sub) {
                return _buildSubjectCard(sub);
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Every attendance session is counted as one class. Multiple classes held on the same date are counted separately.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OVERALL CARD
  // ============================================================

  Widget _buildOverallCard() {
    final Color statusColor = _getStatusColor(_overallPercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: (_overallPercentage / 100).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      statusColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_overallPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Attendance',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _getStatus(_overallPercentage),
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_overallAttended / $_overallTotal classes attended',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(
    Map<String, dynamic> sub,
  ) {
    final int attended = sub['attended'] as int;

    final int total = sub['total'] as int;

    final double percentage = sub['pct'] as double;

    final Color color = _getStatusColor(percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub['code'].toString(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        sub['name'].toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 9,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 17,
                        color: Colors.green,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Present: $attended',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 17,
                        color: Colors.blue,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Total: $total',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  size: 17,
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  'Absent: ${total - attended}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 65,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
