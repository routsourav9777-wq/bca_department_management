import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanAttendanceScreen extends StatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  State<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends State<ScanAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
    ],
  );

  bool _processing = false;

  // ============================================================
  // CURRENT DATE
  // ============================================================

  String _todayText() {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');

    final month = now.month.toString().padLeft(2, '0');

    return '$day/$month/${now.year}';
  }

  // ============================================================
  // NORMALIZE SEMESTER
  //
  // Student Firebase may contain:
  // "1"
  // "Semester 1"
  //
  // QR contains:
  // "Semester 1"
  // ============================================================

  String _normalizeSemester(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim().toLowerCase();

    return text
        .replaceAll(
          'semester',
          '',
        )
        .trim();
  }

  // ============================================================
  // SCAN HANDLER
  // ============================================================

  Future<void> _handleBarcode(
    BarcodeCapture capture,
  ) async {
    if (_processing) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String? rawValue = capture.barcodes.first.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

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
      // DECODE QR JSON
      // ========================================================

      Map<String, dynamic> qrData;

      try {
        final decoded = jsonDecode(qrText);

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'Invalid QR format.',
          );
        }

        qrData = decoded;
      } catch (_) {
        throw Exception(
          'This is not a valid attendance QR.',
        );
      }

      // ========================================================
      // CHECK QR TYPE
      // ========================================================

      if (qrData['type'] != 'attendance') {
        throw Exception(
          'Invalid attendance QR.',
        );
      }

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
      // CHECK QR TIMESTAMP
      //
      // QR changes every 1 second.
      //
      // Allow 3 seconds because scanner/network
      // can take a little time.
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
      // CHECK DATE
      // ========================================================

      if (qrDate.isNotEmpty && qrDate != _todayText()) {
        throw Exception(
          'This QR is not for today.',
        );
      }

      // ========================================================
      // GET STUDENT DOCUMENT
      // ========================================================

      QuerySnapshot<Map<String, dynamic>> studentQuery = await _firestore
          .collection('students')
          .where(
            'uid',
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      // Fallback to email
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

      final studentDoc = studentQuery.docs.first;

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

      if (studentDepartment.toLowerCase() != qrDepartment.toLowerCase()) {
        throw Exception(
          'This attendance is not for your department.',
        );
      }

      // ========================================================
      // SEMESTER CHECK
      // ========================================================

      if (_normalizeSemester(
            studentSemester,
          ) !=
          _normalizeSemester(
            qrSemester,
          )) {
        throw Exception(
          'This attendance is not for your semester.',
        );
      }

      // ========================================================
      // GET ATTENDANCE SESSION
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> sessionDoc = await _firestore
          .collection(
            'attendance_sessions',
          )
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception(
          'Attendance session not found.',
        );
      }

      final Map<String, dynamic> session = sessionDoc.data()!;

      // ========================================================
      // SESSION STATUS
      // ========================================================

      final String status = session['status']?.toString().toLowerCase() ?? '';

      if (status != 'active') {
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
      // DUPLICATE CHECK
      //
      // Same student cannot mark twice
      // in the same attendance session.
      // ========================================================

      final String recordId = '${sessionId}_$studentUid';

      final DocumentReference<Map<String, dynamic>> recordRef = _firestore
          .collection(
            'attendance_records',
          )
          .doc(recordId);

      final DocumentSnapshot<Map<String, dynamic>> existingRecord =
          await recordRef.get();

      if (existingRecord.exists) {
        throw Exception(
          'Attendance already marked for this class.',
        );
      }

      // ========================================================
      // SAVE ATTENDANCE
      // ========================================================

      await recordRef.set({
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
        'attendanceDate': Timestamp.now(),
        'attendanceDateText': _todayText(),
        'markedAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            title: const Text(
              'Attendance Marked',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  qrSubjectName.isNotEmpty ? qrSubjectName : 'Attendance',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  _todayText(),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Status: PRESENT (P)',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Done',
                  ),
                ),
              ),
            ],
          );
        },
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

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 55,
            ),
            title: const Text(
              'Attendance Failed',
              textAlign: TextAlign.center,
            ),
            content: Text(
              message,
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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

      if (!mounted) return;

      setState(() {
        _processing = false;
      });

      await _scannerController.start();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Attendance',
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.flash_on,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.flip_camera_android,
            ),
            onPressed: () {
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
          // CENTER SCANNER BOX
          // ======================================================

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    top: -2,
                    left: 25,
                    right: 25,
                    child: Divider(
                      color: Colors.blue,
                      thickness: 4,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: 25,
                    right: 25,
                    child: Divider(
                      color: Colors.blue,
                      thickness: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // INSTRUCTION
          // ======================================================

          Positioned(
            left: 24,
            right: 24,
            bottom: 45,
            child: Container(
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  0.70,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Scan Faculty / HOD Attendance QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Keep the changing QR inside the box.',
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
              color: Colors.black.withOpacity(
                0.65,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Verifying attendance...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// SCANNER OVERLAY
// ================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint = Paint()..color = Colors.black.withOpacity(0.55);

    final double boxSize = 280;

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
            20,
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
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
