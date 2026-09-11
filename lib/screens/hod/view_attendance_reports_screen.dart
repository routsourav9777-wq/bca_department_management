import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../services/attendance_excel_service.dart';

class ViewAttendanceReportsScreen extends StatefulWidget {
  const ViewAttendanceReportsScreen({super.key});

  @override
  State<ViewAttendanceReportsScreen> createState() =>
      _ViewAttendanceReportsScreenState();
}

class _ViewAttendanceReportsScreenState
    extends State<ViewAttendanceReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedSem = AppConstants.semesters.isNotEmpty
      ? AppConstants.semesters.first
      : 'Semester 1';

  String? _selectedSubjectId;
  String? _selectedSubjectName;

  int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  bool _loadingSubjects = true;
  bool _loadingReport = false;
  bool _downloading = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _subjects = [];
  List<AttendanceStudent> _students = [];

  int _totalClasses = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _loadingReport = false;
      _errorMessage = null;
      _subjects = [];
      _students = [];
      _selectedSubjectId = null;
      _selectedSubjectName = null;
      _totalClasses = 0;
      _totalPresent = 0;
      _totalAbsent = 0;
    });

    try {
      final snapshot = await _firestore
          .collection('subjects')
          .where('department', isEqualTo: 'BCA')
          .get();

      final List<Map<String, dynamic>> subjects = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final String semester = (data['semester'] ?? '').toString().trim();

        if (_normalizeSemester(semester) == _normalizeSemester(_selectedSem)) {
          subjects.add({
            'id': doc.id,
            'name': (data['subjectName'] ??
                    data['name'] ??
                    data['subject'] ??
                    'Unnamed Subject')
                .toString(),
          });
        }
      }

      subjects.sort(
        (a, b) => a['name'].toString().toLowerCase().compareTo(
              b['name'].toString().toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _subjects = subjects;
        _loadingSubjects = false;

        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'].toString();

          _selectedSubjectName = _subjects.first['name'].toString();
        }
      });

      if (_subjects.isNotEmpty) {
        await _loadAttendanceReport();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSubjects = false;
        _errorMessage = 'Failed to load subjects:\n$e';
      });
    }
  }

  // ============================================================
  // LOAD ATTENDANCE REPORT
  // ============================================================

  Future<void> _loadAttendanceReport() async {
    final String? subjectId = _selectedSubjectId;

    if (subjectId == null || subjectId.isEmpty) {
      return;
    }

    setState(() {
      _loadingReport = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where(
            'subjectId',
            isEqualTo: subjectId,
          )
          .get();

      final Map<String, AttendanceStudentData> studentData = {};

      final Set<int> classDays = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final int year = _toInt(data['year']);

        final int month = _toInt(data['month']);

        if (year != _selectedYear || month != _selectedMonth) {
          continue;
        }

        final String studentUid = (data['studentUid'] ?? '').toString().trim();

        final String studentName =
            (data['studentName'] ?? data['name'] ?? 'Unknown Student')
                .toString()
                .trim();

        final String rollNo = (data['rollNo'] ?? '').toString().trim();

        if (studentUid.isEmpty) {
          continue;
        }

        studentData.putIfAbsent(
          studentUid,
          () => AttendanceStudentData(
            uid: studentUid,
            rollNo: rollNo,
            name: studentName,
            presentDays: <int>{},
          ),
        );

        final dynamic daysData = data['days'];

        if (daysData is! Map) {
          continue;
        }

        daysData.forEach(
          (dynamic key, dynamic value) {
            final int? day = int.tryParse(key.toString());

            if (day == null) {
              return;
            }

            final String status = value.toString().trim().toUpperCase();

            if (status == 'P' || status == 'A') {
              classDays.add(day);
            }

            if (status == 'P') {
              studentData[studentUid]!.presentDays.add(day);
            }
          },
        );
      }

      final List<AttendanceStudent> report = [];

      for (final student in studentData.values) {
        final int attended = student.presentDays.length;

        final int totalClasses = classDays.length;

        final int absent =
            totalClasses > attended ? totalClasses - attended : 0;

        final double percentage =
            totalClasses == 0 ? 0 : (attended / totalClasses) * 100;

        report.add(
          AttendanceStudent(
            uid: student.uid,
            rollNo: student.rollNo,
            name: student.name,
            totalClasses: totalClasses,
            attended: attended,
            absent: absent,
            percentage: percentage,
          ),
        );
      }

      report.sort(
        (a, b) => a.rollNo.compareTo(b.rollNo),
      );

      final int totalPresent = report.fold(
        0,
        (sum, student) => sum + student.attended,
      );

      final int totalAbsent = report.fold(
        0,
        (sum, student) => sum + student.absent,
      );

      if (!mounted) return;

      setState(() {
        _students = report;
        _totalClasses = classDays.length;
        _totalPresent = totalPresent;
        _totalAbsent = totalAbsent;
        _loadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingReport = false;
        _errorMessage = 'Failed to load attendance:\n$e';
      });
    }
  }

  // ============================================================
  // DELETE STUDENT FROM ATTENDANCE
  //
  // IMPORTANT:
  // This does NOT delete the student's profile.
  // It deletes only this student's attendance.
  // ============================================================

  Future<void> _deleteStudentAttendance(
    AttendanceStudent student,
  ) async {
    // ==========================================================
    // CONFIRMATION
    // ==========================================================

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Attendance?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Delete ${student.name} from this attendance report?\n\n'
            'Roll No: ${student.rollNo}\n\n'
            'Only this student\'s attendance will be removed. '
            'Other students will not be affected.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // ==========================================================
    // UID CHECK
    // ==========================================================

    if (student.uid.isEmpty) {
      _showMessage(
        'Student UID not found.',
        Colors.red,
      );
      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _loadingReport = true;
    });

    try {
      // ========================================================
      // 1. DELETE FROM MONTHLY ATTENDANCE
      //
      // Only matching studentUid is deleted.
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> attendanceSnapshot =
          await _firestore
              .collection('attendance')
              .where(
                'studentUid',
                isEqualTo: student.uid,
              )
              .get();

      WriteBatch batch = _firestore.batch();

      int operationCount = 0;

      for (final doc in attendanceSnapshot.docs) {
        batch.delete(
          doc.reference,
        );

        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();

          batch = _firestore.batch();

          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      // ========================================================
      // 2. DELETE FROM ATTENDANCE RECORDS
      //
      // This also removes session-wise records.
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> recordsSnapshot =
          await _firestore
              .collection(
                'attendance_records',
              )
              .where(
                'studentUid',
                isEqualTo: student.uid,
              )
              .get();

      batch = _firestore.batch();

      operationCount = 0;

      for (final doc in recordsSnapshot.docs) {
        batch.delete(
          doc.reference,
        );

        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();

          batch = _firestore.batch();

          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      // ========================================================
      // 3. REMOVE FROM CURRENT SCREEN IMMEDIATELY
      // ========================================================

      if (!mounted) return;

      setState(() {
        _students.removeWhere(
          (item) => item.uid == student.uid,
        );

        _loadingReport = false;
      });

      // ========================================================
      // 4. RELOAD REPORT
      //
      // This recalculates total present/absent/classes.
      // ========================================================

      await _loadAttendanceReport();

      if (!mounted) return;

      _showMessage(
        '${student.name} removed from attendance successfully.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingReport = false;
      });

      _showMessage(
        'Failed to delete attendance:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // DOWNLOAD ATTENDANCE
  // ============================================================

  Future<void> _downloadAttendance() async {
    if (_selectedSubjectId == null ||
        _selectedSubjectName == null ||
        _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No attendance data available to download.',
          ),
        ),
      );
      return;
    }

    final String? format = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Download Attendance',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  _selectedSubjectName!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),

                // EXCEL
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        'excel',
                      );
                    },
                    icon: const Icon(
                      Icons.table_chart,
                    ),
                    label: const Text(
                      'Download Excel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // PDF
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        'pdf',
                      );
                    },
                    icon: const Icon(
                      Icons.picture_as_pdf,
                    ),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (format == null) {
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      // ========================================================
      // CREATE SHEET DATA
      // ========================================================

      final List<AttendanceSheetStudent> sheetStudents = [];

      final snapshot = await _firestore
          .collection('attendance')
          .where(
            'subjectId',
            isEqualTo: _selectedSubjectId,
          )
          .get();

      final Map<String, Map<int, String>> attendanceByStudent = {};

      final Set<int> classDays = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final int year = _toInt(data['year']);

        final int month = _toInt(data['month']);

        if (year != _selectedYear || month != _selectedMonth) {
          continue;
        }

        final String studentUid = (data['studentUid'] ?? '').toString().trim();

        if (studentUid.isEmpty) {
          continue;
        }

        attendanceByStudent.putIfAbsent(
          studentUid,
          () => <int, String>{},
        );

        final dynamic daysData = data['days'];

        if (daysData is! Map) {
          continue;
        }

        daysData.forEach(
          (dynamic key, dynamic value) {
            final int? day = int.tryParse(
              key.toString(),
            );

            if (day == null) {
              return;
            }

            final String status = value.toString().trim().toUpperCase();

            if (status == 'P' || status == 'A') {
              classDays.add(day);

              attendanceByStudent[studentUid]![day] = status;
            }
          },
        );
      }

      // ========================================================
      // BUILD SHEET DATA
      //
      // IMPORTANT:
      // _students already contains only students
      // that are currently in the report.
      //
      // Deleted student will therefore NOT appear.
      // ========================================================

      for (final student in _students) {
        final Map<int, String> attendance = {};

        for (final day in classDays) {
          attendance[day] = attendanceByStudent[student.uid]?[day] ?? 'A';
        }

        sheetStudents.add(
          AttendanceSheetStudent(
            rollNo: student.rollNo,
            name: student.name,
            attendance: attendance,
          ),
        );
      }

      // ========================================================
      // EXCEL
      // ========================================================

      if (format == 'excel') {
        await AttendanceExcelService.downloadExcel(
          subjectName: _selectedSubjectName!,
          semester: _selectedSem,
          month: _selectedMonth,
          year: _selectedYear,
          students: sheetStudents,
          batch: '2026 AB',
          facultyName: '',
        );
      }

      // ========================================================
      // PDF
      // ========================================================

      if (format == 'pdf') {
        await AttendanceExcelService.downloadPdf(
          subjectName: _selectedSubjectName!,
          semester: _selectedSem,
          month: _selectedMonth,
          year: _selectedYear,
          students: sheetStudents,
          batch: '2026 AB',
          facultyName: '',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == 'excel'
                ? 'Attendance Excel downloaded successfully.'
                : 'Attendance PDF downloaded successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download failed:\n$e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _downloading = false;
      });
    }
  }

  // ============================================================
  // NORMALIZE SEMESTER
  // ============================================================

  String _normalizeSemester(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll(
          'semester',
          '',
        )
        .replaceAll(
          'sem',
          '',
        )
        .replaceAll(
          RegExp(r'[^0-9]'),
          '',
        )
        .trim();
  }

  // ============================================================
  // SAFE INT
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName(
    int month,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: (_loadingSubjects || _loadingReport || _downloading)
                ? null
                : _loadSubjects,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(
            height: 1,
          ),
          Expanded(
            child: _buildReportBody(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              // SEMESTER
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSem,
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: AppConstants.semesters
                      .map(
                        (semester) => DropdownMenuItem<String>(
                          value: semester,
                          child: Text(semester),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null || value == _selectedSem) {
                      return;
                    }

                    setState(() {
                      _selectedSem = value;
                    });

                    await _loadSubjects();
                  },
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // MONTH
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: List.generate(
                    12,
                    (index) {
                      final month = index + 1;

                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          _monthName(
                            month,
                          ),
                        ),
                      );
                    },
                  ),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedMonth = value;
                    });

                    await _loadAttendanceReport();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // SUBJECT
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId,
            decoration: InputDecoration(
              labelText: 'Subject',
              prefixIcon: const Icon(
                Icons.menu_book,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _subjects.map(
              (subject) {
                return DropdownMenuItem<String>(
                  value: subject['id'].toString(),
                  child: Text(
                    subject['name'].toString(),
                  ),
                );
              },
            ).toList(),
            onChanged: _subjects.isEmpty
                ? null
                : (value) async {
                    if (value == null) {
                      return;
                    }

                    final selected = _subjects.firstWhere(
                      (subject) => subject['id'].toString() == value,
                    );

                    setState(() {
                      _selectedSubjectId = value;

                      _selectedSubjectName = selected['name'].toString();
                    });

                    await _loadAttendanceReport();
                  },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT BODY
  // ============================================================

  Widget _buildReportBody() {
    if (_loadingSubjects || _loadingReport) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.red,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                onPressed: _loadSubjects,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                'No subjects found for this semester.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceReport,
      child: ListView(
        padding: const EdgeInsets.all(
          16,
        ),
        children: [
          _buildSummaryCard(),

          const SizedBox(
            height: 16,
          ),

          if (_students.isEmpty)
            _buildEmptyAttendance()
          else
            ..._students.map(
              _buildStudentCard,
            ),

          const SizedBox(
            height: 16,
          ),

          // DOWNLOAD BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_downloading || _students.isEmpty)
                  ? null
                  : _downloadAttendance,
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.download,
                    ),
              label: Text(
                _downloading
                    ? 'Preparing Attendance...'
                    : 'Download Attendance',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedSubjectName ?? 'Attendance Report',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              '$_selectedSem • '
              '${_monthName(_selectedMonth)} '
              '$_selectedYear',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    icon: Icons.calendar_month,
                    title: 'Classes',
                    value: '$_totalClasses',
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    icon: Icons.check_circle,
                    title: 'Present',
                    value: '$_totalPresent',
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    icon: Icons.cancel,
                    title: 'Absent',
                    value: '$_totalAbsent',
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
  // SUMMARY ITEM
  // ============================================================

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 26,
          color: Colors.blue,
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(
    AttendanceStudent student,
  ) {
    final bool shortage = student.percentage < 75;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Row(
          children: [
            // ==================================================
            // ATTENDANCE %
            // ==================================================

            CircleAvatar(
              radius: 28,
              backgroundColor:
                  shortage ? Colors.red.shade100 : Colors.green.shade100,
              child: Text(
                '${student.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: shortage ? Colors.red.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ==================================================
            // STUDENT DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name.isEmpty ? 'Unknown Student' : student.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    student.rollNo.isEmpty
                        ? 'Roll No: N/A'
                        : 'Roll No: ${student.rollNo}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Present: ${student.attended} / '
                    '${student.totalClasses}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            // ==================================================
            // SHORTAGE / OK
            // ==================================================

            if (shortage)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(
                    8,
                  ),
                ),
                child: const Text(
                  'Shortage',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),

            // ==================================================
            // 3 DOT MENU
            // ==================================================

            PopupMenuButton<String>(
              tooltip: 'Student options',
              icon: const Icon(
                Icons.more_vert,
                color: Colors.blueGrey,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteStudentAttendance(
                    student,
                  );
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 21,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Delete Attendance',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyAttendance() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Column(
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'No attendance found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'No attendance has been marked for '
              'this subject in '
              '${_monthName(_selectedMonth)} '
              '$_selectedYear.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TEMPORARY ATTENDANCE DATA
// ============================================================

class AttendanceStudentData {
  final String uid;
  final String rollNo;
  final String name;
  final Set<int> presentDays;

  AttendanceStudentData({
    required this.uid,
    required this.rollNo,
    required this.name,
    required this.presentDays,
  });
}

// ============================================================
// FINAL ATTENDANCE STUDENT
// ============================================================

class AttendanceStudent {
  final String uid;
  final String rollNo;
  final String name;
  final int totalClasses;
  final int attended;
  final int absent;
  final double percentage;

  AttendanceStudent({
    required this.uid,
    required this.rollNo,
    required this.name,
    required this.totalClasses,
    required this.attended,
    required this.absent,
    required this.percentage,
  });
}
