import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // SEMESTER
  // ============================================================

  final List<String> _semesters = const [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  String _selectedSemester = 'Semester 1';

  String? _selectedSubjectId;

  Map<String, dynamic>? _selectedSubject;

  bool _loadingSubjects = false;
  bool _generatingQR = false;

  // ============================================================
  // ACTIVE QR SESSION
  // ============================================================

  String? _sessionId;

  String? _sessionSecret;

  String _currentQrData = '';

  Timer? _qrTimer;

  int _qrSecond = 0;

  int _presentCount = 0;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _attendanceSubscription;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSubjects();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _qrTimer?.cancel();

    _attendanceSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // CURRENT DATE
  // ============================================================

  DateTime get _today {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // ============================================================
  // DATE TEXT
  // ============================================================

  String get _formattedDate {
    final date = _today;

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // FIREBASE DATE
  // ============================================================

  Timestamp get _firebaseToday {
    return Timestamp.fromDate(_today);
  }

  // ============================================================
  // LOAD SUBJECTS
  //
  // HOD-added subjects:
  //
  // subjects
  //   name
  //   code
  //   semester
  //   department
  //   status
  //
  // ============================================================

  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _selectedSubjectId = null;
      _selectedSubject = null;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('subjects')
          .where(
            'department',
            isEqualTo: 'BCA',
          )
          .where(
            'semester',
            isEqualTo: _selectedSemester,
          )
          .get();

      final docs = snapshot.docs;

      if (!mounted) return;

      if (docs.isNotEmpty) {
        final first = docs.first;

        setState(() {
          _selectedSubjectId = first.id;

          _selectedSubject = {
            ...first.data(),
            'id': first.id,
          };
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load subjects: '
            '${e.message ?? e.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading subjects: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingSubjects = false;
        });
      }
    }
  }

  // ============================================================
  // RANDOM SECRET
  // ============================================================

  String _generateSecret() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789';

    final Random random = Random.secure();

    return List.generate(
      48,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  // ============================================================
  // START QR ROTATION
  //
  // QR CHANGES EVERY 1 SECOND
  //
  // NO AUTOMATIC CLOSE
  //
  // ============================================================

  void _startQrRotation() {
    _qrTimer?.cancel();

    _qrSecond = 0;

    _updateQr();

    _qrTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        _qrSecond++;

        _updateQr();
      },
    );
  }

  // ============================================================
  // UPDATE QR DATA
  // ============================================================

  void _updateQr() {
    if (_sessionId == null || _sessionSecret == null) {
      return;
    }

    final int currentSecond = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final Map<String, dynamic> qrPayload = {
      'type': 'attendance',

      'version': 1,

      'sessionId': _sessionId,

      // Changes every second
      'timestamp': currentSecond,

      'secret': _sessionSecret,

      'department': 'BCA',

      'semester': _selectedSemester,

      'subjectId': _selectedSubjectId,

      'subjectName': _selectedSubject?['name']?.toString() ?? '',

      // Current attendance date
      'attendanceDate': _formattedDate,
    };

    final String encoded = jsonEncode(qrPayload);

    if (!mounted) return;

    setState(() {
      _currentQrData = encoded;
    });
  }

  // ============================================================
  // GENERATE ATTENDANCE SESSION
  // ============================================================

  Future<void> _generateAttendanceQR() async {
    if (_selectedSubjectId == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a subject first.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Close previous session if any
    await _closeCurrentSession(
      showMessage: false,
    );

    setState(() {
      _generatingQR = true;
    });

    try {
      final String secret = _generateSecret();

      final DocumentReference<Map<String, dynamic>> sessionRef = _firestore
          .collection(
            'attendance_sessions',
          )
          .doc();

      // ========================================================
      // CREATE SESSION
      // ========================================================

      await sessionRef.set({
        'sessionId': sessionRef.id,

        'secret': secret,

        'facultyUid': user.uid,

        'facultyEmail': user.email ?? '',

        'subjectId': _selectedSubjectId,

        'subjectName': _selectedSubject?['name']?.toString() ?? '',

        'subjectCode': _selectedSubject?['code']?.toString() ?? '',

        'department': 'BCA',

        'semester': _selectedSemester,

        // IMPORTANT:
        // Current attendance date
        'attendanceDate': _firebaseToday,

        'attendanceDateText': _formattedDate,

        'createdAt': FieldValue.serverTimestamp(),

        // No expiry
        'status': 'active',

        'presentCount': 0,
      });

      if (!mounted) return;

      setState(() {
        _sessionId = sessionRef.id;

        _sessionSecret = secret;

        _presentCount = 0;

        _currentQrData = '';
      });

      // Start 1-second QR rotation
      _startQrRotation();

      // Listen to students
      _listenToPresentCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live QR started. QR changes every 1 second.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase Error: '
            '${e.message ?? e.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingQR = false;
        });
      }
    }
  }

  // ============================================================
  // LIVE PRESENT COUNT
  // ============================================================

  void _listenToPresentCount() {
    _attendanceSubscription?.cancel();

    if (_sessionId == null) {
      return;
    }

    _attendanceSubscription = _firestore
        .collection(
          'attendance_records',
        )
        .where(
          'sessionId',
          isEqualTo: _sessionId,
        )
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        setState(() {
          _presentCount = snapshot.docs.length;
        });
      },
    );
  }

  // ============================================================
  // CLOSE SESSION MANUALLY
  // ============================================================

  Future<void> _closeCurrentSession({
    bool showMessage = true,
  }) async {
    _qrTimer?.cancel();

    _attendanceSubscription?.cancel();

    if (_sessionId != null) {
      try {
        await _firestore
            .collection(
              'attendance_sessions',
            )
            .doc(_sessionId)
            .update({
          'status': 'closed',
          'closedAt': FieldValue.serverTimestamp(),
          'presentCount': _presentCount,
        });
      } catch (e) {
        debugPrint(
          'Close attendance session error: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _sessionId = null;

      _sessionSecret = null;

      _currentQrData = '';

      _presentCount = 0;

      _qrSecond = 0;
    });

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Attendance session closed.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ============================================================
  // CHANGE SEMESTER
  // ============================================================

  Future<void> _changeSemester(
    String? value,
  ) async {
    if (value == null) return;

    if (_sessionId != null) {
      await _closeCurrentSession(
        showMessage: false,
      );
    }

    setState(() {
      _selectedSemester = value;
    });

    await _loadSubjects();
  }

  // ============================================================
  // SUBJECT DISPLAY
  // ============================================================

  String _subjectDisplayName(
    Map<String, dynamic> subject,
  ) {
    final String code = subject['code']?.toString() ?? '';

    final String name = subject['name']?.toString() ?? 'Unnamed Subject';

    if (code.isEmpty) {
      return name;
    }

    return '$code - $name';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Attendance',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // INFO
              // ==================================================

              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.blue.shade700,
                        size: 34,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live QR Attendance',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              'QR changes every 1 second. Faculty/HOD must manually close the attendance session.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // SEMESTER DROPDOWN
              // ==================================================

              DropdownButtonFormField<String>(
                initialValue: _selectedSemester,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: const Icon(
                    Icons.school_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                items: _semesters
                    .map(
                      (semester) => DropdownMenuItem<String>(
                        value: semester,
                        child: Text(
                          semester,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _changeSemester,
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // SUBJECT DROPDOWN
              // ==================================================

              _buildSubjectDropdown(),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // GENERATE BUTTON
              // ==================================================

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generatingQR ? null : _generateAttendanceQR,
                  icon: _generatingQR
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_2,
                        ),
                  label: Text(
                    _generatingQR ? 'Generating...' : 'Generate Live QR',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // QR CARD
              // ==================================================

              if (_sessionId != null) _buildLiveQrCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBJECT DROPDOWN
  // ============================================================

  Widget _buildSubjectDropdown() {
    if (_loadingSubjects) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('subjects')
          .where(
            'department',
            isEqualTo: 'BCA',
          )
          .where(
            'semester',
            isEqualTo: _selectedSemester,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              'Unable to load subjects.\n'
              '${snapshot.error}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'No subjects added by HOD for this semester.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final bool selectedExists = docs.any(
          (doc) => doc.id == _selectedSubjectId,
        );

        if (!selectedExists) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (!mounted) return;

              final first = docs.first;

              setState(() {
                _selectedSubjectId = first.id;

                _selectedSubject = {
                  ...first.data(),
                  'id': first.id,
                };
              });
            },
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: selectedExists ? _selectedSubjectId : docs.first.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Subject',
            prefixIcon: const Icon(
              Icons.menu_book_outlined,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
          items: docs.map(
            (doc) {
              final data = doc.data();

              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(
                  _subjectDisplayName(
                    data,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            final doc = docs.firstWhere(
              (d) => d.id == value,
            );

            setState(() {
              _selectedSubjectId = value;

              _selectedSubject = {
                ...doc.data(),
                'id': doc.id,
              };
            });
          },
        );
      },
    );
  }

  // ============================================================
  // LIVE QR CARD
  // ============================================================

  Widget _buildLiveQrCard() {
    final String subjectName = _selectedSubject == null
        ? ''
        : _subjectDisplayName(
            _selectedSubject!,
          );

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // ACTIVE STATUS
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                const Text(
                  'LIVE QR ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // SUBJECT
            // ==================================================

            Text(
              subjectName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              _selectedSemester,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // QR CODE
            // ==================================================

            Container(
              padding: const EdgeInsets.all(
                14,
              ),
              color: Colors.white,
              child: _currentQrData.isEmpty
                  ? const SizedBox(
                      width: 260,
                      height: 260,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : QrImageView(
                      key: ValueKey(
                        _currentQrData,
                      ),
                      data: _currentQrData,
                      version: QrVersions.auto,
                      size: 260,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DATE BELOW QR
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ATTENDANCE DATE',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // LIVE CHANGE TEXT
            // ==================================================

            const Text(
              'QR changes automatically every 1 second',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PRESENT COUNT
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                14,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.how_to_reg,
                    color: Colors.green,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Expanded(
                    child: Text(
                      'Students Present',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$_presentCount',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // MANUAL CLOSE ONLY
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _closeCurrentSession,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.red,
                ),
                label: const Text(
                  'Close Attendance Session',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'The session will remain active until you manually close it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
