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
  State<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState
    extends State<MarkAttendanceScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // SEMESTERS
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
  // QR SESSION
  // ============================================================

  String? _sessionId;

  String? _sessionSecret;

  String _currentQrData = '';

  Timer? _qrTimer;

  int _qrSecond = 0;

  // ============================================================
  // PRESENT COUNT
  // ============================================================

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

  // ============================================================
  // DATE TEXT
  // ============================================================

  String get _formattedDate {
    final DateTime date = _today;

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

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
  // ============================================================

  Future<void> _loadSubjects() async {
    if (mounted) {
      setState(() {
        _loadingSubjects = true;
        _selectedSubjectId = null;
        _selectedSubject = null;
      });
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
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

      if (!mounted) return;

      final docs = snapshot.docs;

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

      _showMessage(
        'Unable to load subjects:\n'
        '${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error loading subjects:\n$e',
        error: true,
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
    const String characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789';

    final Random random =
        Random.secure();

    return List.generate(
      48,
      (_) => characters[
          random.nextInt(
            characters.length,
          )],
    ).join();
  }

  // ============================================================
  // START QR ROTATION
  // ============================================================

  void _startQrRotation() {
    _qrTimer?.cancel();

    _qrSecond = 0;

    _updateQr();

    _qrTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
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
  // UPDATE QR
  // ============================================================

  void _updateQr() {
    if (_sessionId == null ||
        _sessionSecret == null ||
        _selectedSubjectId == null) {
      return;
    }

    final int currentSecond =
        DateTime.now()
                .millisecondsSinceEpoch ~/
            1000;

    final Map<String, dynamic>
        qrPayload = {
      'type': 'attendance',

      'version': 2,

      'sessionId':
          _sessionId,

      'timestamp':
          currentSecond,

      'secret':
          _sessionSecret,

      'department':
          'BCA',

      'semester':
          _selectedSemester,

      'subjectId':
          _selectedSubjectId,

      'subjectName':
          _selectedSubject?['name']
                  ?.toString() ??
              '',

      'attendanceDate':
          _formattedDate,

      'year':
          _today.year,

      'month':
          _today.month,

      'day':
          _today.day,
    };

    final String encoded =
        jsonEncode(qrPayload);

    if (!mounted) return;

    setState(() {
      _currentQrData =
          encoded;
    });
  }

  // ============================================================
  // GENERATE ATTENDANCE QR
  // ============================================================

  Future<void>
      _generateAttendanceQR() async {
    if (_selectedSubjectId == null ||
        _selectedSubject == null) {
      _showMessage(
        'Please select a subject first.',
        error: true,
      );

      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
        error: true,
      );

      return;
    }

    // Close previous session
    if (_sessionId != null) {
      await _closeCurrentSession(
        showMessage: false,
      );
    }

    if (!mounted) return;

    setState(() {
      _generatingQR = true;
    });

    try {
      final String secret =
          _generateSecret();

      final DocumentReference<
              Map<String, dynamic>>
          sessionRef =
          _firestore
              .collection(
                'attendance_sessions',
              )
              .doc();

      // ========================================================
      // CREATE SESSION
      // ========================================================

      await sessionRef.set({
        'sessionId':
            sessionRef.id,

        'secret':
            secret,

        'facultyUid':
            user.uid,

        'facultyEmail':
            user.email ?? '',

        'subjectId':
            _selectedSubjectId,

        'subjectName':
            _selectedSubject?['name']
                    ?.toString() ??
                '',

        'subjectCode':
            _selectedSubject?['code']
                    ?.toString() ??
                '',

        'department':
            'BCA',

        'semester':
            _selectedSemester,

        'attendanceDate':
            _firebaseToday,

        'attendanceDateText':
            _formattedDate,

        'year':
            _today.year,

        'month':
            _today.month,

        'day':
            _today.day,

        'createdAt':
            FieldValue.serverTimestamp(),

        'status':
            'active',

        'presentCount':
            0,
      });

      if (!mounted) return;

      setState(() {
        _sessionId =
            sessionRef.id;

        _sessionSecret =
            secret;

        _presentCount = 0;

        _currentQrData = '';
      });

      // Start QR rotation
      _startQrRotation();

      // Start realtime attendance count
      _listenToPresentCount();

      _showMessage(
        'Live QR started. QR changes every 1 second.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Firebase Error:\n'
        '${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error:\n$e',
        error: true,
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
  // PRESENT COUNT
  //
  // IMPORTANT:
  //
  // We DO NOT use attendance_records here.
  //
  // Actual attendance is:
  //
  // attendance
  //   student_subject_year_month
  //
  // days.12 = P
  //
  // We check:
  //
  // 1. subjectId
  // 2. month
  // 3. lastAttendanceDate = today
  // 4. days.today = P
  //
  // ============================================================

  void _listenToPresentCount() {
    _attendanceSubscription?.cancel();

    if (_selectedSubjectId == null) {
      if (mounted) {
        setState(() {
          _presentCount = 0;
        });
      }

      return;
    }

    final String subjectId =
        _selectedSubjectId!;

    _attendanceSubscription =
        _firestore
            .collection('attendance')
            .where(
              'subjectId',
              isEqualTo: subjectId,
            )
            .snapshots()
            .listen(
      (
        QuerySnapshot<
                Map<String, dynamic>>
            snapshot,
      ) {
        final DateTime today =
            _today;

        final String todayDay =
            today.day.toString();

        int count = 0;

        // ======================================================
        // CHECK EVERY ATTENDANCE DOCUMENT
        // ======================================================

        for (final doc
            in snapshot.docs) {
          final Map<String, dynamic>
              data =
              doc.data();

          // ----------------------------------------------------
          // MONTH CHECK
          // ----------------------------------------------------

          final dynamic monthValue =
              data['month'];

          int? month;

          if (monthValue is int) {
            month = monthValue;
          } else {
            month = int.tryParse(
              monthValue?.toString() ??
                  '',
            );
          }

          if (month != today.month) {
            continue;
          }

          // ----------------------------------------------------
          // LAST ATTENDANCE DATE
          // ----------------------------------------------------

          final dynamic
              lastAttendanceDate =
              data[
                  'lastAttendanceDate'];

          if (lastAttendanceDate
              is! Timestamp) {
            continue;
          }

          final DateTime
              attendanceDate =
              lastAttendanceDate
                  .toDate();

          // ----------------------------------------------------
          // MUST BE TODAY
          // ----------------------------------------------------

          final bool isToday =
              attendanceDate.year ==
                      today.year &&
                  attendanceDate.month ==
                      today.month &&
                  attendanceDate.day ==
                      today.day;

          if (!isToday) {
            continue;
          }

          // ----------------------------------------------------
          // DAYS
          // ----------------------------------------------------

          final dynamic days =
              data['days'];

          if (days is! Map) {
            continue;
          }

          // ----------------------------------------------------
          // TODAY P?
          // ----------------------------------------------------

          final dynamic status =
              days[todayDay];

          if (status
                  ?.toString()
                  .trim()
                  .toUpperCase() ==
              'P') {
            count++;
          }
        }

        // ======================================================
        // DEBUG
        // ======================================================

        debugPrint(
          '--------------------------------',
        );

        debugPrint(
          'Attendance subject: $subjectId',
        );

        debugPrint(
          'Attendance date: $_formattedDate',
        );

        debugPrint(
          'Attendance documents: '
          '${snapshot.docs.length}',
        );

        debugPrint(
          'Present count: $count',
        );

        debugPrint(
          '--------------------------------',
        );

        // ======================================================
        // UPDATE SCREEN
        // ======================================================

        if (!mounted) return;

        setState(() {
          _presentCount =
              count;
        });

        // ======================================================
        // UPDATE SESSION COUNT
        // ======================================================

        _updateFirebaseSessionCount(
          count,
        );
      },
      onError: (Object error) {
        debugPrint(
          'Attendance count error: $error',
        );
      },
    );
  }

  // ============================================================
  // UPDATE FIREBASE SESSION COUNT
  // ============================================================

  Future<void>
      _updateFirebaseSessionCount(
    int count,
  ) async {
    final String? sessionId =
        _sessionId;

    if (sessionId == null) {
      return;
    }

    try {
      await _firestore
          .collection(
            'attendance_sessions',
          )
          .doc(sessionId)
          .update({
        'presentCount':
            count,

        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Session count update error: $e',
      );
    }
  }

  // ============================================================
  // CLOSE SESSION
  // ============================================================

  Future<void>
      _closeCurrentSession({
    bool showMessage = true,
  }) async {
    _qrTimer?.cancel();

    _attendanceSubscription
        ?.cancel();

    if (_sessionId != null) {
      try {
        await _firestore
            .collection(
              'attendance_sessions',
            )
            .doc(_sessionId)
            .update({
          'status':
              'closed',

          'closedAt':
              FieldValue.serverTimestamp(),

          'presentCount':
              _presentCount,
        });
      } catch (e) {
        debugPrint(
          'Close session error: $e',
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
      _showMessage(
        'Attendance session closed.',
        color: Colors.orange,
      );
    }
  }

  // ============================================================
  // CHANGE SEMESTER
  // ============================================================

  Future<void> _changeSemester(
    String? value,
  ) async {
    if (value == null) {
      return;
    }

    if (_sessionId != null) {
      await _closeCurrentSession(
        showMessage: false,
      );
    }

    if (!mounted) return;

    setState(() {
      _selectedSemester =
          value;

      _selectedSubjectId =
          null;

      _selectedSubject =
          null;

      _presentCount = 0;
    });

    await _loadSubjects();
  }

  // ============================================================
  // SUBJECT DISPLAY NAME
  // ============================================================

  String _subjectDisplayName(
    Map<String, dynamic>
        subject,
  ) {
    final String code =
        subject['code']
                ?.toString() ??
            '';

    final String name =
        subject['name']
                ?.toString() ??
            'Unnamed Subject';

    if (code.isEmpty) {
      return name;
    }

    return '$code - $name';
  }

  // ============================================================
  // SUBJECT DROPDOWN
  // ============================================================

  Widget _buildSubjectDropdown() {
    if (_loadingSubjects) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: _firestore
          .collection('subjects')
          .where(
            'department',
            isEqualTo: 'BCA',
          )
          .where(
            'semester',
            isEqualTo:
                _selectedSemester,
          )
          .snapshots(),

      builder: (
        BuildContext context,
        AsyncSnapshot<
                QuerySnapshot<
                    Map<String, dynamic>>>
            snapshot,
      ) {
        if (snapshot.hasError) {
          return Container(
            padding:
                const EdgeInsets.all(
              14,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.red.shade50,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              'Unable to load subjects.\n'
              '${snapshot.error}',
              style:
                  const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return Container(
            padding:
                const EdgeInsets.all(
              16,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.orange.shade50,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color:
                      Colors.orange,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'No subjects added by HOD for this semester.',
                    style:
                        TextStyle(
                      color:
                          Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final bool
            selectedExists =
            docs.any(
          (doc) =>
              doc.id ==
              _selectedSubjectId,
        );

        if (!selectedExists) {
          WidgetsBinding.instance
              .addPostFrameCallback(
            (_) {
              if (!mounted) return;

              final first =
                  docs.first;

              setState(() {
                _selectedSubjectId =
                    first.id;

                _selectedSubject = {
                  ...first.data(),
                  'id': first.id,
                };
              });
            },
          );
        }

        return DropdownButtonFormField<
            String>(
          initialValue:
              selectedExists
                  ? _selectedSubjectId
                  : docs.first.id,

          isExpanded: true,

          decoration:
              InputDecoration(
            labelText:
                'Subject',

            prefixIcon:
                const Icon(
              Icons
                  .menu_book_outlined,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
          ),

          items: docs.map(
            (
              QueryDocumentSnapshot<
                      Map<String,
                          dynamic>>
                  doc,
            ) {
              final Map<String,
                      dynamic>
                  data =
                  doc.data();

              return DropdownMenuItem<
                  String>(
                value:
                    doc.id,

                child:
                    Text(
                  _subjectDisplayName(
                    data,
                  ),
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              );
            },
          ).toList(),

          onChanged:
              (String? value) {
            if (value == null) {
              return;
            }

            final doc =
                docs.firstWhere(
              (d) =>
                  d.id == value,
            );

            setState(() {
              _selectedSubjectId =
                  value;

              _selectedSubject = {
                ...doc.data(),
                'id': doc.id,
              };

              _presentCount = 0;
            });

            // If QR is already active,
            // listen for the selected subject.
            if (_sessionId != null) {
              _listenToPresentCount();
            }
          },
        );
      },
    );
  }

  // ============================================================
  // LIVE QR CARD
  // ============================================================

  Widget _buildLiveQrCard() {
    final String subjectName =
        _selectedSubject == null
            ? ''
            : _subjectDisplayName(
                _selectedSubject!,
              );

    return Card(
      elevation: 5,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(
          children: [
            // ==================================================
            // ACTIVE STATUS
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                Container(
                  width: 10,
                  height: 10,

                  decoration:
                      const BoxDecoration(
                    color:
                        Colors.green,
                    shape:
                        BoxShape.circle,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Text(
                  'LIVE QR ACTIVE',

                  style:
                      TextStyle(
                    color:
                        Colors.green,
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        15,
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

              textAlign:
                  TextAlign.center,

              maxLines: 2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              _selectedSemester,

              style:
                  const TextStyle(
                color:
                    Colors.grey,
                fontSize:
                    12,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // QR
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),

              color:
                  Colors.white,

              child:
                  _currentQrData
                          .isEmpty
                      ? const SizedBox(
                          width:
                              260,
                          height:
                              260,
                          child:
                              Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        )
                      : QrImageView(
                          key:
                              ValueKey(
                            _currentQrData,
                          ),

                          data:
                              _currentQrData,

                          version:
                              QrVersions
                                  .auto,

                          size:
                              260,

                          backgroundColor:
                              Colors
                                  .white,

                          errorCorrectionLevel:
                              QrErrorCorrectLevel
                                  .H,
                        ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DATE
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.blue.shade50,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  Column(
                children: [
                  const Text(
                    'ATTENDANCE DATE',

                    style:
                        TextStyle(
                      color:
                          Colors.blue,
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing:
                          1.0,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    _formattedDate,

                    style:
                        const TextStyle(
                      fontSize:
                          20,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'QR changes automatically every 1 second',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.blue,
                fontSize:
                    12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // PRESENT COUNT
            // ==================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.green.shade50,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  Row(
                children: [
                  const Icon(
                    Icons.how_to_reg,

                    color:
                        Colors.green,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Expanded(
                    child:
                        Text(
                      'Students Present',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    '$_presentCount',

                    style:
                        const TextStyle(
                      fontSize:
                          22,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // MANUAL CLOSE
            // ==================================================

            SizedBox(
              width:
                  double.infinity,

              height:
                  50,

              child:
                  OutlinedButton.icon(
                onPressed:
                    _closeCurrentSession,

                icon:
                    const Icon(
                  Icons
                      .stop_circle_outlined,

                  color:
                      Colors.red,
                ),

                label:
                    const Text(
                  'Close Attendance Session',
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      Colors.red,

                  side:
                      const BorderSide(
                    color:
                        Colors.red,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
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

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.grey,
                fontSize:
                    11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
    Color? color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),

        backgroundColor:
            color ??
                (error
                    ? Colors.red
                    : Colors.green),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'QR Attendance',
        ),
      ),

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [
              // ==================================================
              // INFO
              // ==================================================

              Card(
                color:
                    Colors.blue.shade50,

                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    16,
                  ),

                  child:
                      Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Icon(
                        Icons
                            .qr_code_scanner,

                        color:
                            Colors.blue
                                .shade700,

                        size:
                            34,
                      ),

                      const SizedBox(
                        width:
                            12,
                      ),

                      const Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              'Live QR Attendance',

                              style:
                                  TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            SizedBox(
                              height:
                                  5,
                            ),

                            Text(
                              'QR changes every 1 second. Faculty/HOD must manually close the attendance session.',

                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color:
                                    Colors.grey,
                                height:
                                    1.4,
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
                height:
                    16,
              ),

              // ==================================================
              // SEMESTER
              // ==================================================

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _selectedSemester,

                isExpanded:
                    true,

                decoration:
                    InputDecoration(
                  labelText:
                      'Semester',

                  prefixIcon:
                      const Icon(
                    Icons
                        .school_outlined,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                ),

                items:
                    _semesters
                        .map(
                  (
                    String semester,
                  ) {
                    return DropdownMenuItem<
                        String>(
                      value:
                          semester,

                      child:
                          Text(
                        semester,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ).toList(),

                onChanged:
                    _changeSemester,
              ),

              const SizedBox(
                height:
                    16,
              ),

              // ==================================================
              // SUBJECT
              // ==================================================

              _buildSubjectDropdown(),

              const SizedBox(
                height:
                    20,
              ),

              // ==================================================
              // GENERATE
              // ==================================================

              SizedBox(
                height:
                    52,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      _generatingQR
                          ? null
                          : _generateAttendanceQR,

                  icon:
                      _generatingQR
                          ? const SizedBox(
                              width:
                                  20,
                              height:
                                  20,

                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,

                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .qr_code_2,
                            ),

                  label:
                      Text(
                    _generatingQR
                        ? 'Generating...'
                        : 'Generate Live QR',

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    20,
              ),

              // ==================================================
              // QR CARD
              // ==================================================

              if (_sessionId != null)
                _buildLiveQrCard(),
            ],
          ),
        ),
      ),
    );
  }
}