import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanAttendanceScreen extends StatefulWidget {
  const ScanAttendanceScreen({
    super.key,
  });

  @override
  State<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends State<ScanAttendanceScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
    ],
  );

  bool _processing = false;
  bool _showSuccessAnimation = false;

  String _successStudentName = '';
  String _successSubjectName = '';

  late AnimationController _scanLineController;
  late AnimationController _successController;
  late AnimationController _particleController;
  late AnimationController _boxPulseController;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _boxPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _scanLineController.dispose();
    _successController.dispose();
    _particleController.dispose();
    _boxPulseController.dispose();
    _scannerController.dispose();

    super.dispose();
  }

  // ============================================================
  // TODAY
  // ============================================================

  DateTime get _today {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  String _todayText() {
    final DateTime now = _today;

    final String day = now.day.toString().padLeft(2, '0');
    final String month = now.month.toString().padLeft(2, '0');

    return '$day/$month/${now.year}';
  }

  // ============================================================
  // NORMALIZE SEMESTER
  // ============================================================

  String _normalizeSemester(dynamic value) {
    if (value == null) {
      return '';
    }

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
  // BARCODE
  // ============================================================

  Future<void> _handleBarcode(
    BarcodeCapture capture,
  ) async {
    if (_processing || _showSuccessAnimation) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String? rawValue = capture.barcodes.first.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _processing = true;
    });

    await _scannerController.stop();

    await _processAttendance(
      rawValue.trim(),
    );
  }

  // ============================================================
  // PROCESS ATTENDANCE
  // ============================================================

  Future<void> _processAttendance(
    String qrText,
  ) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please login again.',
        );
      }

      // ========================================================
      // DECODE QR
      // ========================================================

      Map<String, dynamic> qrData;

      try {
        final dynamic decoded = jsonDecode(qrText);

        if (decoded is! Map<String, dynamic>) {
          throw Exception();
        }

        qrData = decoded;
      } catch (_) {
        throw Exception(
          'This is not a valid attendance QR.',
        );
      }

      // ========================================================
      // QR TYPE
      // ========================================================

      if (qrData['type'] != 'attendance') {
        throw Exception(
          'Invalid attendance QR.',
        );
      }

      // ========================================================
      // QR DATA
      // ========================================================

      final String sessionId = qrData['sessionId']?.toString() ?? '';

      final String secret = qrData['secret']?.toString() ?? '';

      final String qrDepartment = qrData['department']?.toString() ?? '';

      final String qrSemester = qrData['semester']?.toString() ?? '';

      final String qrSubjectId = qrData['subjectId']?.toString() ?? '';

      final String qrSubjectName = qrData['subjectName']?.toString() ?? '';

      final String qrDate = qrData['attendanceDate']?.toString() ?? '';

      final dynamic timestampValue = qrData['timestamp'];

      if (sessionId.isEmpty ||
          secret.isEmpty ||
          qrDepartment.isEmpty ||
          qrSemester.isEmpty ||
          qrSubjectId.isEmpty ||
          timestampValue == null) {
        throw Exception(
          'Incomplete attendance QR.',
        );
      }

      // ========================================================
      // QR TIME VALIDATION
      // ========================================================

      final int qrTimestamp = int.tryParse(
            timestampValue.toString(),
          ) ??
          0;

      final int currentTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final int difference = (currentTimestamp - qrTimestamp).abs();

      if (difference > 3) {
        throw Exception(
          'QR expired. Please scan the current QR.',
        );
      }

      // ========================================================
      // DATE CHECK
      // ========================================================

      if (qrDate.isNotEmpty && qrDate != _todayText()) {
        throw Exception(
          'This QR is not for today.',
        );
      }

      // ========================================================
      // GET STUDENT
      // ========================================================

      QuerySnapshot<Map<String, dynamic>> studentQuery = await _firestore
          .collection('students')
          .where(
            'uid',
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      // ========================================================
      // EMAIL FALLBACK
      // ========================================================

      if (studentQuery.docs.isEmpty && user.email != null) {
        studentQuery = await _firestore
            .collection('students')
            .where(
              'email',
              isEqualTo: user.email,
            )
            .limit(1)
            .get();
      }

      if (studentQuery.docs.isEmpty) {
        throw Exception(
          'Student profile not found.',
        );
      }

      final QueryDocumentSnapshot<Map<String, dynamic>> studentDoc =
          studentQuery.docs.first;

      final Map<String, dynamic> student = studentDoc.data();

      // ========================================================
      // STUDENT DATA
      // ========================================================

      final String studentUid = user.uid;

      final String studentName = student['name']?.toString() ?? 'Student';

      final String rollNo = student['rollNo']?.toString() ??
          student['rollNumber']?.toString() ??
          '';

      final String studentDepartment =
          student['department']?.toString() ?? 'BCA';

      final String studentSemester = student['semester']?.toString() ?? '';

      // ========================================================
      // DEPARTMENT CHECK
      // ========================================================

      if (studentDepartment.trim().toLowerCase() !=
          qrDepartment.trim().toLowerCase()) {
        throw Exception(
          'This attendance is not for your department.',
        );
      }

      // ========================================================
      // SEMESTER CHECK
      // ========================================================

      if (_normalizeSemester(studentSemester) !=
          _normalizeSemester(qrSemester)) {
        throw Exception(
          'This attendance is not for your semester.',
        );
      }

      // ========================================================
      // SESSION
      // ========================================================

      final DocumentReference<Map<String, dynamic>> sessionRef =
          _firestore.collection('attendance_sessions').doc(sessionId);

      final DocumentSnapshot<Map<String, dynamic>> sessionDoc =
          await sessionRef.get();

      if (!sessionDoc.exists) {
        throw Exception(
          'Attendance session not found.',
        );
      }

      final Map<String, dynamic> session = sessionDoc.data()!;

      // ========================================================
      // SESSION STATUS
      // ========================================================

      final String sessionStatus =
          session['status']?.toString().toLowerCase() ?? '';

      if (sessionStatus != 'active') {
        throw Exception(
          'Attendance session has been closed.',
        );
      }

      // ========================================================
      // SECRET CHECK
      // ========================================================

      final String sessionSecret = session['secret']?.toString() ?? '';

      if (sessionSecret != secret) {
        throw Exception(
          'Invalid attendance QR.',
        );
      }

      // ========================================================
      // SUBJECT CHECK
      // ========================================================

      final String sessionSubjectId = session['subjectId']?.toString() ?? '';

      if (sessionSubjectId != qrSubjectId) {
        throw Exception(
          'Invalid subject.',
        );
      }

      // ========================================================
      // SESSION DATE CHECK
      // ========================================================

      final String sessionDate =
          session['attendanceDateText']?.toString() ?? '';

      if (sessionDate.isNotEmpty && sessionDate != _todayText()) {
        throw Exception(
          'This attendance session is from another date.',
        );
      }

      // ========================================================
      // DATE VARIABLES
      // ========================================================

      final DateTime today = _today;

      final String dayKey = today.day.toString();

      final String monthKey = today.month.toString().padLeft(
            2,
            '0',
          );

      // ========================================================
      // MONTHLY ATTENDANCE DOCUMENT
      // ========================================================

      final String attendanceDocId = '${studentUid}_'
          '${qrSubjectId}_'
          '${today.year}_'
          '$monthKey';

      final DocumentReference<Map<String, dynamic>> attendanceRef =
          _firestore.collection('attendance').doc(attendanceDocId);

      // ========================================================
      // SESSION ATTENDANCE RECORD
      // ========================================================

      final String recordId = '${sessionId}_$studentUid';

      final DocumentReference<Map<String, dynamic>> recordRef =
          _firestore.collection('attendance_records').doc(recordId);

      // ========================================================
      // TRANSACTION
      // ========================================================

      bool alreadyPresent = false;

      await _firestore.runTransaction(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<Map<String, dynamic>> attendanceSnapshot =
              await transaction.get(
            attendanceRef,
          );

          final DocumentSnapshot<Map<String, dynamic>> recordSnapshot =
              await transaction.get(
            recordRef,
          );

          // ----------------------------------------------------
          // MONTHLY DUPLICATE
          // ----------------------------------------------------

          if (attendanceSnapshot.exists) {
            final Map<String, dynamic> oldData =
                attendanceSnapshot.data() ?? <String, dynamic>{};

            final dynamic oldDays = oldData['days'];

            if (oldDays is Map) {
              final dynamic todayStatus = oldDays[dayKey];

              if (todayStatus?.toString().trim().toUpperCase() == 'P') {
                alreadyPresent = true;

                return;
              }
            }
          }

          // ----------------------------------------------------
          // SESSION DUPLICATE
          // ----------------------------------------------------

          if (recordSnapshot.exists) {
            alreadyPresent = true;

            return;
          }

          // ----------------------------------------------------
          // OLD DAYS
          // ----------------------------------------------------

          Map<String, dynamic> days = <String, dynamic>{};

          int totalPresent = 0;
          int totalDays = 0;

          if (attendanceSnapshot.exists) {
            final Map<String, dynamic> oldData =
                attendanceSnapshot.data() ?? <String, dynamic>{};

            final dynamic oldDays = oldData['days'];

            if (oldDays is Map) {
              days = Map<String, dynamic>.from(
                oldDays,
              );
            }

            final dynamic oldPresent = oldData['totalPresent'];

            if (oldPresent is int) {
              totalPresent = oldPresent;
            } else {
              totalPresent = int.tryParse(
                    oldPresent?.toString() ?? '',
                  ) ??
                  0;
            }

            final dynamic oldTotalDays = oldData['totalDays'];

            if (oldTotalDays is int) {
              totalDays = oldTotalDays;
            } else {
              totalDays = int.tryParse(
                    oldTotalDays?.toString() ?? '',
                  ) ??
                  days.length;
            }
          }

          // ----------------------------------------------------
          // MARK PRESENT
          // ----------------------------------------------------

          days[dayKey] = 'P';

          totalPresent++;

          totalDays = days.length;

          // ----------------------------------------------------
          // SAVE MONTHLY ATTENDANCE
          // ----------------------------------------------------

          transaction.set(
            attendanceRef,
            {
              'studentUid': studentUid,
              'studentName': studentName,
              'rollNo': rollNo,
              'email': user.email ?? '',
              'department': studentDepartment,
              'semester': studentSemester,
              'subjectId': qrSubjectId,
              'subjectName': qrSubjectName.isNotEmpty
                  ? qrSubjectName
                  : session['subjectName']?.toString() ?? '',
              'year': today.year,
              'month': today.month,
              'lastAttendanceDate': Timestamp.fromDate(today),
              'days': days,
              'totalPresent': totalPresent,
              'totalDays': totalDays,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );

          // ----------------------------------------------------
          // SAVE SESSION RECORD
          // ----------------------------------------------------

          transaction.set(
            recordRef,
            {
              'sessionId': sessionId,
              'studentUid': studentUid,
              'studentName': studentName,
              'rollNo': rollNo,
              'email': user.email ?? '',
              'department': studentDepartment,
              'semester': studentSemester,
              'subjectId': qrSubjectId,
              'subjectName': qrSubjectName.isNotEmpty
                  ? qrSubjectName
                  : session['subjectName']?.toString() ?? '',
              'status': 'present',
              'statusShort': 'P',
              'attendanceDate': Timestamp.fromDate(today),
              'attendanceDateText': _todayText(),
              'markedAt': FieldValue.serverTimestamp(),
            },
          );
        },
      );

      // ========================================================
      // DUPLICATE RESULT
      // ========================================================

      if (alreadyPresent) {
        throw Exception(
          'Attendance already marked for this subject today.',
        );
      }

      // ========================================================
      // UPDATE SESSION COUNT
      // ========================================================

      await _updateSessionPresentCount(
        sessionRef: sessionRef,
        subjectId: qrSubjectId,
        year: today.year,
        month: today.month,
        day: today.day,
      );

      // ========================================================
      // SUCCESS ANIMATION
      // ========================================================

      if (!mounted) return;

      setState(() {
        _successStudentName = studentName;

        _successSubjectName = qrSubjectName.isNotEmpty
            ? qrSubjectName
            : session['subjectName']?.toString() ?? 'Attendance';

        _processing = false;
        _showSuccessAnimation = true;
      });

      _successController.forward(from: 0);
      _particleController.forward(from: 0);

      // Let the Paytm-style animation play.
      await Future.delayed(
        const Duration(
          milliseconds: 2200,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      final String message = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      await _showErrorDialog(
        message,
      );
    } finally {
      if (!mounted) return;

      if (!_showSuccessAnimation) {
        setState(() {
          _processing = false;
        });

        await _scannerController.start();
      }
    }
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  Future<void> _showErrorDialog(
    String message,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: const Color(
            0xFF10131A,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          icon: const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 58,
          ),
          title: const Text(
            'Attendance Failed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 228, 229, 232),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                    double.infinity,
                    48,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Try Again',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UPDATE SESSION PRESENT COUNT
  // ============================================================

  Future<void> _updateSessionPresentCount({
    required DocumentReference<Map<String, dynamic>> sessionRef,
    required String subjectId,
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('attendance')
          .where(
            'subjectId',
            isEqualTo: subjectId,
          )
          .where(
            'year',
            isEqualTo: year,
          )
          .where(
            'month',
            isEqualTo: month,
          )
          .get();

      final String dayKey = day.toString();

      final Set<String> students = <String>{};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        final dynamic days = data['days'];

        if (days is Map) {
          final dynamic status = days[dayKey];

          if (status?.toString().trim().toUpperCase() == 'P') {
            final String studentUid = data['studentUid']?.toString() ?? doc.id;

            students.add(
              studentUid,
            );
          }
        }
      }

      final int count = students.length;

      debugPrint(
        'SUBJECT: $subjectId',
      );

      debugPrint(
        'DATE: ${_todayText()}',
      );

      debugPrint(
        'PRESENT COUNT: $count',
      );

      await sessionRef.update({
        'presentCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Unable to update session count: $e',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Flash',
            icon: const Icon(
              Icons.flash_on_rounded,
            ),
            onPressed: _showSuccessAnimation
                ? null
                : () {
                    _scannerController.toggleTorch();
                  },
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(
              Icons.flip_camera_android_rounded,
            ),
            onPressed: _showSuccessAnimation
                ? null
                : () {
                    _scannerController.switchCamera();
                  },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // CAMERA
          // ======================================================

          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // ======================================================
          // 3D SCANNER FRAME
          // ======================================================

          Center(
            child: AnimatedBuilder(
              animation: _boxPulseController,
              builder: (
                context,
                child,
              ) {
                final double pulse = 0.75 + (_boxPulseController.value * 0.25);

                return Transform.scale(
                  scale: pulse,
                  child: child,
                );
              },
              child: const SizedBox(
                width: 290,
                height: 290,
                child: Stack(
                  children: [
                    // Shadow frame
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                              28,
                            ),
                          ),
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: Colors.white70,
                              width: 2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(255, 252, 253, 255),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top-left
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _CornerShape(
                        rotate: 0,
                      ),
                    ),

                    // Top-right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _CornerShape(
                        rotate: math.pi / 2,
                      ),
                    ),

                    // Bottom-right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _CornerShape(
                        rotate: math.pi,
                      ),
                    ),

                    // Bottom-left
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _CornerShape(
                        rotate: -math.pi / 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // ANIMATED SCANNING LINE
          // ======================================================

          if (!_showSuccessAnimation)
            Center(
              child: SizedBox(
                width: 265,
                height: 265,
                child: AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (
                    context,
                    child,
                  ) {
                    final double y = 8 + (_scanLineController.value * 249);

                    return Stack(
                      children: [
                        Positioned(
                          top: y,
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(0, 236, 233, 233),
                                  Color.fromARGB(255, 246, 249, 255),
                                  Color.fromARGB(255, 246, 249, 255),
                                  Color.fromARGB(0, 236, 233, 233),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 173, 216, 255)
                                      .withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 14,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // ======================================================
          // INSTRUCTION
          // ======================================================

          if (!_showSuccessAnimation)
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.72,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.4,
                      ),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Scan Attendance QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Keep the changing QR inside the box',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // PROCESSING
          // ======================================================

          if (_processing)
            Container(
              color: Colors.black.withValues(
                alpha: 0.68,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 55,
                      height: 55,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    Text(
                      'Verifying attendance...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // PAYTM STYLE SUCCESS ANIMATION
          // ======================================================

          if (_showSuccessAnimation)
            Positioned.fill(
              child: _AttendanceSuccessAnimation(
                successController: _successController,
                particleController: _particleController,
                studentName: _successStudentName,
                subjectName: _successSubjectName,
                date: _todayText(),
              ),
            ),
        ],
      ),
    );
  }
}

// =================================================================
// CORNER SHAPE
// =================================================================

class _CornerShape extends StatelessWidget {
  final double rotate;

  const _CornerShape({
    required this.rotate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.cyanAccent,
              width: 6,
            ),
            left: BorderSide(
              color: Colors.cyanAccent,
              width: 6,
            ),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// SUCCESS ANIMATION
// =================================================================

class _AttendanceSuccessAnimation extends StatelessWidget {
  final AnimationController successController;
  final AnimationController particleController;

  final String studentName;
  final String subjectName;
  final String date;

  const _AttendanceSuccessAnimation({
    required this.successController,
    required this.particleController,
    required this.studentName,
    required this.subjectName,
    required this.date,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(
        0xFF06110B,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          successController,
          particleController,
        ]),
        builder: (
          context,
          child,
        ) {
          final double value = Curves.easeOutCubic.transform(
            successController.value,
          );

          final double scale = 0.35 + (value * 0.65);

          final double fade = Curves.easeOut.transform(
            successController.value,
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              // ==================================================
              // PARTICLES
              // ==================================================

              Positioned.fill(
                child: CustomPaint(
                  painter: _SuccessParticlePainter(
                    progress: particleController.value,
                  ),
                ),
              ),

              // ==================================================
              // GLOW
              // ==================================================

              Container(
                width: 230 + (value * 40),
                height: 230 + (value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(
                        alpha: 0.18 * (1 - value * 0.35),
                      ),
                      blurRadius: 90,
                      spreadRadius: 25,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // OUTER RING
              // ==================================================

              Transform.scale(
                scale: scale,
                child: Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.greenAccent.withValues(
                        alpha: 0.35,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // MAIN 3D CIRCLE
              // ==================================================

              Transform.scale(
                scale: scale,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(
                          0xFF58F59A,
                        ),
                        Color(
                          0xFF0DBB5A,
                        ),
                        Color(
                          0xFF07883F,
                        ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(
                          alpha: 0.45,
                        ),
                        blurRadius: 35,
                        spreadRadius: 4,
                      ),
                      const BoxShadow(
                        color: Colors.black45,
                        blurRadius: 12,
                        offset: Offset(
                          6,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 78,
                  ),
                ),
              ),

              // ==================================================
              // TEXT
              // ==================================================

              Positioned(
                left: 25,
                right: 25,
                bottom: 105,
                child: Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      30 * (1 - fade),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Attendance Marked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          studentName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          subjectName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(
                              30,
                            ),
                            border: Border.all(
                              color: Colors.greenAccent.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: const Text(
                            'PRESENT  •  P',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =================================================================
// PARTICLE PAINTER
// =================================================================

class _SuccessParticlePainter extends CustomPainter {
  final double progress;

  _SuccessParticlePainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final Paint paint = Paint()..style = PaintingStyle.fill;

    const int particleCount = 80;

    for (int i = 0; i < particleCount; i++) {
      final double seed = i / particleCount;

      final double angle = seed * math.pi * 2;

      final double wave = math.sin(
        seed * 25,
      );

      final double startRadius = 85 + (wave.abs() * 35);

      final double travel = 40 + (progress * (260 + (i % 5) * 45));

      final double radius = startRadius + travel;

      final double x = center.dx + math.cos(angle) * radius;

      final double y = center.dy + math.sin(angle) * radius;

      final double sizeFactor = 1 - progress * 0.55;

      final double particleSize = (2 + (i % 4) * 1.3) * sizeFactor;

      final double opacity = (1 - progress * 0.8).clamp(0.0, 1.0);

      paint.color = i % 3 == 0
          ? Colors.cyanAccent.withValues(
              alpha: opacity,
            )
          : Colors.greenAccent.withValues(
              alpha: opacity,
            );

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _SuccessParticlePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =================================================================
// SCANNER OVERLAY
// =================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint = Paint()
      ..color = Colors.black.withValues(
        alpha: 0.55,
      );

    const double boxSize = 280;

    final double left = (size.width - boxSize) / 2;

    final double top = (size.height - boxSize) / 2;

    final Path path = Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            top,
            boxSize,
            boxSize,
          ),
          const Radius.circular(
            28,
          ),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
