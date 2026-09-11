import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class UploadNoticeScreen extends StatefulWidget {
  const UploadNoticeScreen({super.key});

  @override
  State<UploadNoticeScreen> createState() => _UploadNoticeScreenState();
}

class _UploadNoticeScreenState extends State<UploadNoticeScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String _targetAudience = 'All Students & Faculty';

  String _selectedSemester = 'Semester 1';

  String _filterSemester = 'All';

  File? _selectedCameraImage;

  String? _selectedImageName;

  File? _selectedPdfFile;

  String? _selectedPdfName;

  bool _isUploading = false;

  // ============================================================
  // SEMESTERS
  // ============================================================

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  // ============================================================
  // OPEN CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    if (_isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      final File file = File(image.path);

      if (!await file.exists()) {
        _showMessage(
          'Captured image was not found.',
          Colors.red,
        );
        return;
      }

      setState(() {
        _selectedCameraImage = file;
        _selectedImageName = image.name;
      });

      _showMessage(
        'Photo captured successfully.',
        Colors.green,
      );
    } catch (e) {
      _showMessage(
        'Camera error:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // PICK PDF
  // ============================================================

  Future<void> _pickPdf() async {
    if (_isUploading) return;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return;
      }

      final PlatformFile pickedFile = result.files.single;

      final File file = File(pickedFile.path!);

      if (!await file.exists()) {
        _showMessage(
          'Selected PDF file was not found.',
          Colors.red,
        );
        return;
      }

      setState(() {
        _selectedPdfFile = file;
        _selectedPdfName = pickedFile.name;
      });

      _showMessage(
        'PDF selected successfully.',
        Colors.green,
      );
    } catch (e) {
      _showMessage(
        'PDF selection error:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage() {
    if (_isUploading) return;

    setState(() {
      _selectedCameraImage = null;
      _selectedImageName = null;
    });
  }

  // ============================================================
  // REMOVE PDF
  // ============================================================

  void _removePdf() {
    if (_isUploading) return;

    setState(() {
      _selectedPdfFile = null;
      _selectedPdfName = null;
    });
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<String?> _uploadImage(
    String noticeId,
  ) async {
    if (_selectedCameraImage == null) {
      return null;
    }

    final String fileName =
        'notice_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final Reference storageRef =
        _storage.ref().child('notice_images').child(noticeId).child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'noticeId': noticeId,
        'type': 'notice_image',
      },
    );

    await storageRef.putFile(
      _selectedCameraImage!,
      metadata,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD PDF
  // ============================================================

  Future<String?> _uploadPdf(
    String noticeId,
  ) async {
    if (_selectedPdfFile == null) {
      return null;
    }

    final String fileName = _selectedPdfName ?? 'notice_document.pdf';

    final Reference storageRef =
        _storage.ref().child('notice_pdfs').child(noticeId).child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'application/pdf',
      customMetadata: {
        'noticeId': noticeId,
        'type': 'notice_pdf',
      },
    );

    await storageRef.putFile(
      _selectedPdfFile!,
      metadata,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // PUBLISH NOTICE
  // ============================================================

  Future<void> _publishNotice() async {
    if (_isUploading) return;

    final String title = _titleController.text.trim();

    final String content = _contentController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      _showError(
        'Please enter notice title.',
      );
      return;
    }

    if (content.isEmpty) {
      _showError(
        'Please enter notice content.',
      );
      return;
    }

    // ==========================================================
    // START UPLOAD
    // ==========================================================

    setState(() {
      _isUploading = true;
    });

    try {
      // ========================================================
      // CREATE DOCUMENT
      // ========================================================

      final DocumentReference<Map<String, dynamic>> noticeRef =
          _firestore.collection('notices').doc();

      final String noticeId = noticeRef.id;

      // ========================================================
      // UPLOAD IMAGE
      // ========================================================

      String? imageUrl;

      if (_selectedCameraImage != null) {
        imageUrl = await _uploadImage(
          noticeId,
        );
      }

      // ========================================================
      // UPLOAD PDF
      // ========================================================

      String? pdfUrl;

      if (_selectedPdfFile != null) {
        pdfUrl = await _uploadPdf(
          noticeId,
        );
      }

      // ========================================================
      // IMPORTANT SEMESTER LOGIC
      // ========================================================
      //
      // Students Only:
      //     Save selected semester.
      //
      // All Students & Faculty:
      //     Save "All".
      //
      // Faculty Members Only:
      //     Save "All".
      //
      // ========================================================

      final String semesterToSave =
          _targetAudience == 'Students Only' ? _selectedSemester : 'All';

      // ========================================================
      // SAVE FIRESTORE
      // ========================================================

      await noticeRef.set({
        'noticeId': noticeId,
        'title': title,
        'content': content,
        'targetAudience': _targetAudience,

        // Fixed semester logic
        'semester': semesterToSave,

        'department': 'BCA',
        'imageUrl': imageUrl,
        'imageName': _selectedImageName,
        'pdfUrl': pdfUrl,
        'pdfName': _selectedPdfName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'published',
        'createdBy': 'department',
        'createdByRole': 'hod',
      });

      if (!mounted) return;

      _showMessage(
        'Department Notice Published Successfully!',
        Colors.green,
      );

      // ========================================================
      // CLEAR FORM
      // ========================================================

      _titleController.clear();

      _contentController.clear();

      setState(() {
        _selectedCameraImage = null;
        _selectedImageName = null;

        _selectedPdfFile = null;
        _selectedPdfName = null;

        _targetAudience = 'All Students & Faculty';

        _selectedSemester = 'Semester 1';

        _isUploading = false;
      });

      // StreamBuilder automatically updates.
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showError(
        'Failed to publish notice:\n$e',
      );
    }
  }

  // ============================================================
  // DELETE NOTICE
  // ============================================================

  Future<void> _deleteNotice(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_isUploading) return;

    final Map<String, dynamic> data = doc.data() ?? {};

    final String noticeId = (data['noticeId'] ?? doc.id).toString();

    final String title = (data['title'] ?? 'this notice').toString();

    // ==========================================================
    // CONFIRM
    // ==========================================================

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Delete Notice?',
          ),
          content: Text(
            'Are you sure you want to delete "$title"?\n\n'
            'The notice and its attached PDF/image '
            'will also be deleted.',
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
                'CANCEL',
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
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // ========================================================
      // DELETE IMAGE STORAGE
      // ========================================================

      try {
        final Reference imageFolder =
            _storage.ref().child('notice_images').child(noticeId);

        final ListResult imageFiles = await imageFolder.listAll();

        for (final Reference file in imageFiles.items) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint(
              'Notice image delete error: $e',
            );
          }
        }
      } catch (e) {
        debugPrint(
          'Notice image folder error: $e',
        );
      }

      // ========================================================
      // DELETE PDF STORAGE
      // ========================================================

      try {
        final Reference pdfFolder =
            _storage.ref().child('notice_pdfs').child(noticeId);

        final ListResult pdfFiles = await pdfFolder.listAll();

        for (final Reference file in pdfFiles.items) {
          try {
            await file.delete();
          } catch (e) {
            debugPrint(
              'Notice PDF delete error: $e',
            );
          }
        }
      } catch (e) {
        debugPrint(
          'Notice PDF folder error: $e',
        );
      }

      // ========================================================
      // DELETE FIRESTORE DOCUMENT
      // ========================================================

      await _firestore.collection('notices').doc(doc.id).delete();

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showMessage(
        'Notice deleted successfully.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showError(
        'Failed to delete notice:\n$e',
      );
    }
  }

  // ============================================================
  // VIEW PDF
  // ============================================================

  Future<void> _viewPdf(
    String url,
    String title,
  ) async {
    final String cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showError(
        'PDF link is not available.',
      );
      return;
    }

    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showError(
        'Invalid PDF link.',
      );
      return;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showError(
          'Unable to open PDF.',
        );
      }
    } catch (e) {
      _showError(
        'Unable to open PDF:\n$e',
      );
    }
  }

  // ============================================================
  // VIEW IMAGE
  // ============================================================

  void _viewImage(
    String url,
    String title,
  ) {
    final String cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showError(
        'Image link is not available.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(
            12,
          ),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.network(
                  cleanUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                  ) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const SizedBox(
                      height: 450,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox(
                      height: 450,
                      child: Center(
                        child: Text(
                          'Unable to load image.',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return 'Date unavailable';
    }

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day = date.day.toString().padLeft(
            2,
            '0',
          );

      final String month = date.month.toString().padLeft(
            2,
            '0',
          );

      return '$day/$month/${date.year}';
    }

    return value.toString();
  }

  // ============================================================
  // NOTICE CARD
  // ============================================================

  Widget _buildNoticeCard(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? {};

    final String title = (data['title'] ?? 'Untitled Notice').toString();

    final String content = (data['content'] ?? '').toString();

    final String semester = (data['semester'] ?? '').toString();

    final String audience =
        (data['targetAudience'] ?? 'All Students & Faculty').toString();

    final String pdfUrl = (data['pdfUrl'] ?? '').toString();

    final String pdfName = (data['pdfName'] ?? '').toString();

    final String imageUrl = (data['imageUrl'] ?? '').toString();

    final String imageName = (data['imageName'] ?? '').toString();

    final String date = _formatDate(
      data['createdAt'],
    );

    final bool hasPdf = pdfUrl.trim().isNotEmpty;

    final bool hasImage = imageUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.orange,
                    size: 27,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

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
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        semester.isEmpty ? 'Semester not specified' : semester,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DELETE
                // ==================================================

                SizedBox(
                  width: 42,
                  height: 42,
                  child: IconButton(
                    tooltip: 'Delete notice',
                    padding: EdgeInsets.zero,
                    onPressed: _isUploading
                        ? null
                        : () => _deleteNotice(
                              doc,
                            ),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // AUDIENCE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    audience,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // DATE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 15,
                  color: Colors.grey,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            if (content.trim().isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(
                    alpha: 0.05,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // ==================================================
            // ATTACHMENTS
            // ==================================================

            if (hasPdf || hasImage) ...[
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  // ==================================================
                  // PDF
                  // ==================================================

                  if (hasPdf)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: Colors.red.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 25,
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Expanded(
                              child: Text(
                                pdfName.isEmpty ? 'PDF' : pdfName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            SizedBox(
                              width: 58,
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () {
                                  _viewPdf(
                                    pdfUrl,
                                    pdfName.isEmpty ? title : pdfName,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text(
                                  'VIEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (hasPdf && hasImage)
                    const SizedBox(
                      width: 8,
                    ),

                  // ==================================================
                  // IMAGE
                  // ==================================================

                  if (hasImage)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: Colors.green.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image,
                              color: Colors.green,
                              size: 25,
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Expanded(
                              child: Text(
                                imageName.isEmpty ? 'Image' : imageName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            SizedBox(
                              width: 58,
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () {
                                  _viewImage(
                                    imageUrl,
                                    imageName.isEmpty ? title : imageName,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text(
                                  'VIEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(
    String message,
  ) {
    _showMessage(
      message,
      Colors.red,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
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
        title: const Text(
          'Upload Department Notice',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // UPLOAD FORM
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Official BCA Department Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'This notice will be visible on student & faculty portals.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    TextField(
                      controller: _titleController,
                      enabled: !_isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        hintText: 'e.g. Mid-Sem Examination Schedule 2026',
                        prefixIcon: Icon(
                          Icons.title,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // AUDIENCE
                    // ==================================================

                    DropdownButtonFormField<String>(
                      initialValue: _targetAudience,
                      decoration: const InputDecoration(
                        labelText: 'Audience / Target',
                        prefixIcon: Icon(
                          Icons.people,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Students & Faculty',
                          child: Text(
                            'All Students & Faculty',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Faculty Members Only',
                          child: Text(
                            'Faculty Members Only',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Students Only',
                          child: Text(
                            'Students Only',
                          ),
                        ),
                      ],
                      onChanged: _isUploading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(
                                  () {
                                    _targetAudience = value;
                                  },
                                );
                              }
                            },
                    ),

                    // ==================================================
                    // SEMESTER
                    //
                    // IMPORTANT:
                    // Only Students Only will show semester.
                    // ==================================================

                    if (_targetAudience == 'Students Only') ...[
                      const SizedBox(
                        height: 16,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Select Semester',
                          prefixIcon: Icon(
                            Icons.school_outlined,
                          ),
                        ),
                        items: _semesters
                            .map(
                              (
                                semester,
                              ) =>
                                  DropdownMenuItem<String>(
                                value: semester,
                                child: Text(
                                  semester,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isUploading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(
                                    () {
                                      _selectedSemester = value;
                                    },
                                  );
                                }
                              },
                      ),
                    ],

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // CONTENT
                    // ==================================================

                    TextField(
                      controller: _contentController,
                      enabled: !_isUploading,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Notice Content / Instructions',
                        hintText: 'Enter detailed notification text here...',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // CAMERA
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _openCamera,
                      icon: const Icon(
                        Icons.camera_alt,
                      ),
                      label: Text(
                        _selectedCameraImage == null
                            ? 'Open Camera'
                            : 'Retake Photo',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // IMAGE PREVIEW
                    // ==================================================

                    if (_selectedCameraImage != null)
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: Image.file(
                                _selectedCameraImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_camera,
                              ),
                              title: Text(
                                _selectedImageName ?? 'Captured Photo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                onPressed: _isUploading ? null : _removeImage,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // PDF
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickPdf,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      label: Text(
                        _selectedPdfName ?? 'Attach Official PDF Document',
                      ),
                    ),

                    if (_selectedPdfFile != null)
                      Card(
                        margin: const EdgeInsets.only(
                          top: 10,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 35,
                          ),
                          title: Text(
                            _selectedPdfName ?? 'PDF Document',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text(
                            'PDF ready to upload',
                          ),
                          trailing: IconButton(
                            onPressed: _isUploading ? null : _removePdf,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // PUBLISH BUTTON
                    // ==================================================

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _publishNotice,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                              ),
                        label: Text(
                          _isUploading
                              ? 'Publishing...'
                              : 'Publish & Broadcast Notice',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // UPLOADED NOTICE HEADER
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Uploaded Department Notices',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ==================================================
                // FILTER
                // ==================================================

                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterSemester,
                      isDense: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text(
                            'All',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ..._semesters.map(
                          (
                            semester,
                          ) =>
                              DropdownMenuItem<String>(
                            value: semester,
                            child: Text(
                              semester,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (
                        value,
                      ) {
                        if (value == null) {
                          return;
                        }

                        setState(
                          () {
                            _filterSemester = value;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ============================================================
            // FIRESTORE NOTICES
            // ============================================================

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection(
                    'notices',
                  )
                  .where(
                    'department',
                    isEqualTo: 'BCA',
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                // ==================================================
                // LOADING
                // ==================================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        30,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                // ==================================================
                // ERROR
                // ==================================================

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 50,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const Text(
                            'Unable to load uploaded notices.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ==================================================
                // FILTER
                // ==================================================

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snapshot.data?.docs.where(
                          (doc) {
                            final Map<String, dynamic> data = doc.data();

                            final String semester =
                                (data['semester'] ?? '').toString().trim();

                            if (_filterSemester == 'All') {
                              return true;
                            }

                            return semester == _filterSemester;
                          },
                        ).toList() ??
                        [];

                // ==================================================
                // SORT NEWEST
                // ==================================================

                docs.sort(
                  (
                    a,
                    b,
                  ) {
                    final dynamic aDate = a.data()['createdAt'];

                    final dynamic bDate = b.data()['createdAt'];

                    if (aDate is Timestamp && bDate is Timestamp) {
                      return bDate.compareTo(
                        aDate,
                      );
                    }

                    return 0;
                  },
                );

                // ==================================================
                // EMPTY
                // ==================================================

                if (docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.campaign_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            _filterSemester == 'All'
                                ? 'No notices uploaded yet.'
                                : 'No notices uploaded for $_filterSemester.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ==================================================
                // LIST
                // ==================================================

                return Column(
                  children: docs.map(
                    (
                      doc,
                    ) {
                      return _buildNoticeCard(
                        doc,
                      );
                    },
                  ).toList(),
                );
              },
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
