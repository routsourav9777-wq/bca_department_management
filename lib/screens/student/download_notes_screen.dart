import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/theme/app_theme.dart';

class DownloadNotesScreen extends StatefulWidget {
  const DownloadNotesScreen({super.key});

  @override
  State<DownloadNotesScreen> createState() => _DownloadNotesScreenState();
}

class _DownloadNotesScreenState extends State<DownloadNotesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'study_notes';

  String? _studentSemester;
  bool _loadingStudent = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  // ============================================================
  // LOAD STUDENT PROFILE
  // ============================================================

  Future<void> _loadStudentProfile() async {
    if (mounted) {
      setState(() {
        _loadingStudent = true;
      });
    }

    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _studentSemester = null;
          _loadingStudent = false;
        });

        return;
      }

      Map<String, dynamic>? studentData;

      // ----------------------------------------------------------
      // METHOD 1: students/{uid}
      // ----------------------------------------------------------

      try {
        final DocumentSnapshot<Map<String, dynamic>> directDoc =
            await _firestore.collection('students').doc(user.uid).get();

        if (directDoc.exists) {
          final Map<String, dynamic>? data = directDoc.data();

          if (data != null) {
            studentData = data;
          }
        }
      } catch (e) {
        debugPrint('Direct student document error: $e');
      }

      // ----------------------------------------------------------
      // METHOD 2: Search uid
      // ----------------------------------------------------------

      if (studentData == null) {
        try {
          final QuerySnapshot<Map<String, dynamic>> uidQuery = await _firestore
              .collection('students')
              .where(
                'uid',
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

          if (uidQuery.docs.isNotEmpty) {
            studentData = uidQuery.docs.first.data();
          }
        } catch (e) {
          debugPrint('Student UID query error: $e');
        }
      }

      // ----------------------------------------------------------
      // METHOD 3: Search email
      // ----------------------------------------------------------

      if (studentData == null &&
          user.email != null &&
          user.email!.trim().isNotEmpty) {
        try {
          final QuerySnapshot<Map<String, dynamic>> emailQuery =
              await _firestore
                  .collection('students')
                  .where(
                    'email',
                    isEqualTo: user.email!.trim(),
                  )
                  .limit(1)
                  .get();

          if (emailQuery.docs.isNotEmpty) {
            studentData = emailQuery.docs.first.data();
          }
        } catch (e) {
          debugPrint('Student email query error: $e');
        }
      }

      // ----------------------------------------------------------
      // GET SEMESTER
      // ----------------------------------------------------------

      String? semester;

      if (studentData != null) {
        semester = _normalizeSemester(
          studentData['semester'] ??
              studentData['currentSemester'] ??
              studentData['sem'],
        );
      }

      debugPrint('Student semester: $semester');

      if (!mounted) return;

      setState(() {
        _studentSemester = semester;
        _loadingStudent = false;
      });
    } catch (e) {
      debugPrint('Student profile loading error: $e');

      if (!mounted) return;

      setState(() {
        _studentSemester = null;
        _loadingStudent = false;
      });
    }
  }

  // ============================================================
  // NORMALIZE SEMESTER
  // ============================================================

  String? _normalizeSemester(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final String lower = text.toLowerCase();

    if (lower == 'semester 1' ||
        lower == 'sem 1' ||
        lower == 'sem1' ||
        lower == '1') {
      return 'Semester 1';
    }

    if (lower == 'semester 2' ||
        lower == 'sem 2' ||
        lower == 'sem2' ||
        lower == '2') {
      return 'Semester 2';
    }

    if (lower == 'semester 3' ||
        lower == 'sem 3' ||
        lower == 'sem3' ||
        lower == '3') {
      return 'Semester 3';
    }

    if (lower == 'semester 4' ||
        lower == 'sem 4' ||
        lower == 'sem4' ||
        lower == '4') {
      return 'Semester 4';
    }

    if (lower == 'semester 5' ||
        lower == 'sem 5' ||
        lower == 'sem5' ||
        lower == '5') {
      return 'Semester 5';
    }

    if (lower == 'semester 6' ||
        lower == 'sem 6' ||
        lower == 'sem6' ||
        lower == '6') {
      return 'Semester 6';
    }

    if (lower.contains('1')) {
      return 'Semester 1';
    }

    if (lower.contains('2')) {
      return 'Semester 2';
    }

    if (lower.contains('3')) {
      return 'Semester 3';
    }

    if (lower.contains('4')) {
      return 'Semester 4';
    }

    if (lower.contains('5')) {
      return 'Semester 5';
    }

    if (lower.contains('6')) {
      return 'Semester 6';
    }

    return text;
  }

  // ============================================================
  // OPEN PDF
  // ============================================================

  void _openPdf(
    BuildContext context,
    String url,
    String title,
  ) {
    final String cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showMessage(
        context,
        'PDF is not available.',
        Colors.red,
      );
      return;
    }

    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showMessage(
        context,
        'Invalid PDF link.',
        Colors.red,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfLoadingScreen(
          pdfUrl: cleanUrl,
          title: title,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN IMAGE
  // ============================================================

  void _openImage(
    BuildContext context,
    String url,
    String title,
  ) {
    final String cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showMessage(
        context,
        'Image is not available.',
        Colors.red,
      );
      return;
    }

    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showMessage(
        context,
        'Invalid image link.',
        Colors.red,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          imageUrl: cleanUrl,
          title: title,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message,
    Color color,
  ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    }

    return value.toString();
  }

  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget _buildNoteCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String title = data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString().trim()
        : 'Untitled Notes';

    final String description = data['description']?.toString().trim() ?? '';

    final String semester = data['semester']?.toString().trim() ?? '';

    final String department =
        data['department']?.toString().trim().isNotEmpty == true
            ? data['department'].toString().trim()
            : 'BCA';

    final String pdfUrl = data['pdfUrl']?.toString().trim() ?? '';

    final String pdfName = data['pdfName']?.toString().trim().isNotEmpty == true
        ? data['pdfName'].toString().trim()
        : 'PDF Notes';

    final String imageUrl = data['imageUrl']?.toString().trim() ?? '';

    final String imageName =
        data['imageName']?.toString().trim().isNotEmpty == true
            ? data['imageName'].toString().trim()
            : 'Camera Image';

    final String date = _formatDate(
      data['createdAt'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TITLE
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.indigo,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$department • $semester',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            // ==================================================
            // PDF
            // ==================================================

            if (pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 30,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pdfName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ==================================================
                    // FIXED VIEW BUTTON
                    // ==================================================

                    SizedBox(
                      width: 82,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          _openPdf(
                            context,
                            pdfUrl,
                            pdfName,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 17,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VIEW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // IMAGE
            // ==================================================

            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image,
                      color: Colors.green,
                      size: 30,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photo Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            imageName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // IMAGE VIEW BUTTON
                    // ==================================================

                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: 'View Image',
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _openImage(
                            context,
                            imageUrl,
                            imageName,
                          );
                        },
                        icon: const Icon(
                          Icons.visibility,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 65,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Notes Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _studentSemester == null
                  ? 'No study materials have been uploaded yet.'
                  : 'No notes available for $_studentSemester.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            if (_studentSemester == null) ...[
              const SizedBox(height: 10),
              const Text(
                'Student semester could not be detected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // LOADING STUDENT
    // ----------------------------------------------------------

    if (_loadingStudent) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Notes'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ----------------------------------------------------------
    // NOT LOGGED IN
    // ----------------------------------------------------------

    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Notes'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'Please login first.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // FIRESTORE QUERY
    // ----------------------------------------------------------

    final Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where(
          'department',
          isEqualTo: 'BCA',
        )
        .where(
          'status',
          isEqualTo: 'published',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          // ------------------------------------------------
          // LOADING
          // ------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------
          // ERROR
          // ------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 55,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadStudentProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ------------------------------------------------
          // NO DATA
          // ------------------------------------------------

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadStudentProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                  ),
                  _buildEmptyView(),
                ],
              ),
            );
          }

          // ------------------------------------------------
          // FILTER BY STUDENT SEMESTER
          // ------------------------------------------------

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> notes =
              snapshot.data!.docs.where((doc) {
            final Map<String, dynamic> data = doc.data();

            final String noteSemester = _normalizeSemester(
                  data['semester'],
                ) ??
                '';

            if (_studentSemester == null || _studentSemester!.isEmpty) {
              return false;
            }

            return noteSemester == _studentSemester;
          }).toList();

          // ------------------------------------------------
          // SORT NEWEST FIRST
          // ------------------------------------------------

          notes.sort((a, b) {
            final dynamic aCreated = a.data()['createdAt'];

            final dynamic bCreated = b.data()['createdAt'];

            if (aCreated is Timestamp && bCreated is Timestamp) {
              return bCreated.compareTo(
                aCreated,
              );
            }

            return 0;
          });

          // ------------------------------------------------
          // NO NOTES FOR SEMESTER
          // ------------------------------------------------

          if (notes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadStudentProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.30,
                  ),
                  _buildEmptyView(),
                ],
              ),
            );
          }

          // ------------------------------------------------
          // NOTES LIST
          // ------------------------------------------------

          return RefreshIndicator(
            onRefresh: _loadStudentProfile,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return _buildNoteCard(
                  context,
                  notes[index].data(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ==================================================================
// PDF LOADING + VIEWER SCREEN
// ==================================================================

class PdfLoadingScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfLoadingScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfLoadingScreen> createState() => _PdfLoadingScreenState();
}

class _PdfLoadingScreenState extends State<PdfLoadingScreen> {
  Uint8List? _pdfBytes;

  bool _loading = true;

  String? _error;

  int? _statusCode;

  int? _byteLength;

  String? _contentType;

  String? _fileHeader;

  @override
  void initState() {
    super.initState();

    _loadPdf();
  }

  // ============================================================
  // LOAD PDF
  // ============================================================

  Future<void> _loadPdf() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _pdfBytes = null;

      _statusCode = null;
      _byteLength = null;
      _contentType = null;
      _fileHeader = null;
    });

    try {
      debugPrint(
        '========================================',
      );
      debugPrint('PDF loading started');
      debugPrint('PDF URL: ${widget.pdfUrl}');
      debugPrint(
        '========================================',
      );

      final Uri uri = Uri.parse(
        widget.pdfUrl,
      );

      final http.Response response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/pdf,*/*',
        },
      ).timeout(
        const Duration(
          seconds: 30,
        ),
      );

      final int statusCode = response.statusCode;

      final int byteLength = response.bodyBytes.length;

      final String contentType = response.headers['content-type'] ?? 'unknown';

      debugPrint(
        'PDF HTTP status: $statusCode',
      );

      debugPrint(
        'PDF content type: $contentType',
      );

      debugPrint(
        'PDF content length: $byteLength',
      );

      // ----------------------------------------------------------
      // STATUS ERROR
      // ----------------------------------------------------------

      if (statusCode < 200 || statusCode >= 300) {
        throw Exception(
          'Server returned $statusCode',
        );
      }

      // ----------------------------------------------------------
      // EMPTY FILE
      // ----------------------------------------------------------

      if (response.bodyBytes.isEmpty) {
        throw Exception(
          'PDF file is empty.',
        );
      }

      final Uint8List bytes = Uint8List.fromList(
        response.bodyBytes,
      );

      // ----------------------------------------------------------
      // HEADER CHECK
      // ----------------------------------------------------------

      String header = '';

      if (bytes.length >= 4) {
        header = String.fromCharCodes(
          bytes.sublist(
            0,
            4,
          ),
        );
      }

      debugPrint(
        'PDF file header: $header',
      );

      if (header != '%PDF') {
        debugPrint(
          'WARNING: File does not start with %PDF',
        );
      }

      // ----------------------------------------------------------
      // FIRST 20 BYTES
      // ----------------------------------------------------------

      final int previewLength = bytes.length < 20 ? bytes.length : 20;

      final String firstBytes = String.fromCharCodes(
        bytes.sublist(
          0,
          previewLength,
        ),
      );

      debugPrint(
        'PDF first bytes: $firstBytes',
      );

      if (!mounted) return;

      setState(() {
        _pdfBytes = bytes;
        _loading = false;

        _statusCode = statusCode;
        _byteLength = byteLength;
        _contentType = contentType;
        _fileHeader = header;
      });

      debugPrint(
        'PDF bytes loaded successfully.',
      );
    } on Exception catch (e) {
      debugPrint(
        'PDF loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _getReadableError(e);
      });
    } catch (e) {
      debugPrint(
        'Unknown PDF error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load PDF.';
      });
    }
  }

  // ============================================================
  // READABLE ERROR
  // ============================================================

  String _getReadableError(
    Exception error,
  ) {
    final String text = error.toString();

    if (text.contains(
      'TimeoutException',
    )) {
      return 'PDF loading timed out.\n\n'
          'Please check your internet connection '
          'and try again.';
    }

    if (text.contains(
      'SocketException',
    )) {
      return 'Internet connection problem.\n\n'
          'Please check your internet connection '
          'and try again.';
    }

    if (text.contains(
      'Server returned 401',
    )) {
      return 'PDF access is unauthorized (401).\n\n'
          'Please check Firebase Storage rules.';
    }

    if (text.contains(
      'Server returned 403',
    )) {
      return 'PDF access is forbidden (403).\n\n'
          'Please check Firebase Storage rules.';
    }

    if (text.contains(
      'Server returned 404',
    )) {
      return 'PDF was not found (404).\n\n'
          'Please ask the teacher to upload '
          'the PDF again.';
    }

    if (text.contains(
      'Server returned',
    )) {
      return 'Unable to access this PDF.\n\n'
          'Please ask the teacher to upload '
          'the PDF again.';
    }

    return 'Unable to load this PDF.\n\n'
        'Please try again.';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // DIAGNOSTIC INFO
  // ============================================================

  Widget _buildDiagnosticInfo() {
    if (_pdfBytes == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        top: 20,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'PDF downloaded successfully',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'HTTP Status: ${_statusCode ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'File Size: ${_byteLength ?? 0} bytes',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Content-Type: ${_contentType ?? '-'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Header: ${_fileHeader ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Loading PDF...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Checking PDF file...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 70,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to open PDF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 140,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _loadPdf,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'TRY AGAIN',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // PDF BYTES AVAILABLE
    // ----------------------------------------------------------

    if (_pdfBytes != null) {
      return Stack(
        children: [
          SfPdfViewer.memory(
            _pdfBytes!,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            onDocumentLoadFailed: (
              PdfDocumentLoadFailedDetails details,
            ) {
              debugPrint(
                '========================================',
              );

              debugPrint(
                'SYNCFUSION PDF VIEWER ERROR',
              );

              debugPrint(
                'Description: ${details.description}',
              );

              debugPrint(
                'Error: ${details.error}',
              );

              debugPrint(
                '========================================',
              );

              if (!mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF viewer error: '
                    '${details.description}',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),

          // Small diagnostic indicator
          Positioned(
            right: 10,
            top: 10,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_byteLength ?? 0} bytes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ----------------------------------------------------------
    // NOTHING
    // ----------------------------------------------------------

    return const Center(
      child: Text(
        'PDF is not available.',
      ),
    );
  }
}

// ==================================================================
// IMAGE VIEWER
// ==================================================================

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (
              context,
              child,
              loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }

              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              debugPrint(
                'Image loading error: $error',
              );

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 70,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Unable to load image.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
