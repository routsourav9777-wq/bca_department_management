import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
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

  final TextEditingController _descController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String _selectedSemester = 'Semester 1';

  File? _selectedPdfFile;
  String? _selectedPdfName;

  File? _selectedCameraImage;
  String? _selectedImageName;

  bool _isUploading = false;

  String _filterSemester = 'All';

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
  // SELECT PDF
  // ============================================================

  Future<void> _selectPdf() async {
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
        'PDF selection failed:\n$e',
        Colors.red,
      );
    }
  }

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
  // UPLOAD PDF TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadPdf(
    String noteId,
  ) async {
    if (_selectedPdfFile == null) {
      return null;
    }

    final String fileName = _selectedPdfName ?? 'note.pdf';

    final Reference storageRef =
        _storage.ref().child('study_notes').child(noteId).child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'application/pdf',
      customMetadata: {
        'noteId': noteId,
        'type': 'study_note_pdf',
      },
    );

    await storageRef.putFile(
      _selectedPdfFile!,
      metadata,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadImage(
    String noteId,
  ) async {
    if (_selectedCameraImage == null) {
      return null;
    }

    final String fileName =
        'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final Reference storageRef =
        _storage.ref().child('study_notes').child(noteId).child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'noteId': noteId,
        'type': 'study_note_image',
      },
    );

    await storageRef.putFile(
      _selectedCameraImage!,
      metadata,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD NOTE
  // ============================================================

  Future<void> _uploadNote() async {
    if (_isUploading) return;

    final String title = _titleController.text.trim();

    final String description = _descController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      _showMessage(
        'Please enter note title.',
        Colors.red,
      );
      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Please enter subject/topic details.',
        Colors.red,
      );
      return;
    }

    if (_selectedPdfFile == null && _selectedCameraImage == null) {
      _showMessage(
        'Please attach a PDF or capture a photo.',
        Colors.red,
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
      // CREATE FIRESTORE DOCUMENT
      // ========================================================

      final DocumentReference<Map<String, dynamic>> noteRef =
          _firestore.collection('study_notes').doc();

      final String noteId = noteRef.id;

      // ========================================================
      // UPLOAD PDF
      // ========================================================

      String? pdfUrl;

      if (_selectedPdfFile != null) {
        pdfUrl = await _uploadPdf(
          noteId,
        );
      }

      // ========================================================
      // UPLOAD CAMERA IMAGE
      // ========================================================

      String? imageUrl;

      if (_selectedCameraImage != null) {
        imageUrl = await _uploadImage(
          noteId,
        );
      }

      // ========================================================
      // SAVE FIRESTORE DATA
      // ========================================================

      await noteRef.set({
        'noteId': noteId,
        'title': title,
        'description': description,
        'semester': _selectedSemester,
        'department': 'BCA',
        'pdfUrl': pdfUrl,
        'pdfName': _selectedPdfName,
        'imageUrl': imageUrl,
        'imageName': _selectedImageName,
        'status': 'published',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showMessage(
        'Study material uploaded successfully!',
        Colors.green,
      );

      // ========================================================
      // CLEAR FORM
      // ========================================================

      _titleController.clear();
      _descController.clear();

      setState(() {
        _selectedPdfFile = null;
        _selectedPdfName = null;

        _selectedCameraImage = null;
        _selectedImageName = null;

        _selectedSemester = 'Semester 1';

        // Show uploaded semester
        _filterSemester = _selectedSemester;
      });

      // No need to manually refresh.
      // StreamBuilder below will update automatically.
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showMessage(
        'Upload failed:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // DELETE NOTE
  // ============================================================

  Future<void> _deleteNote(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (_isUploading) return;

    final Map<String, dynamic> data = doc.data() ?? {};

    final String noteId = (data['noteId'] ?? doc.id).toString();

    final String title = (data['title'] ?? 'this study material').toString();

    // ==========================================================
    // CONFIRMATION
    // ==========================================================

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Study Material?',
          ),
          content: Text(
            'Are you sure you want to delete "$title"?\n\n'
            'The uploaded PDF/image and Firestore record '
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
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

    // ==========================================================
    // SHOW LOADING
    // ==========================================================

    setState(() {
      _isUploading = true;
    });

    try {
      // ========================================================
      // DELETE STORAGE FOLDER
      // ========================================================

      try {
        final Reference folderRef =
            _storage.ref().child('study_notes').child(noteId);

        final ListResult result = await folderRef.listAll();

        for (final Reference fileRef in result.items) {
          try {
            await fileRef.delete();
          } catch (e) {
            debugPrint(
              'Storage file delete error: $e',
            );
          }
        }
      } catch (e) {
        debugPrint(
          'Storage folder delete error: $e',
        );
      }

      // ========================================================
      // DELETE FIRESTORE DOCUMENT
      // ========================================================

      await _firestore.collection('study_notes').doc(doc.id).delete();

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showMessage(
        'Study material deleted successfully.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showMessage(
        'Delete failed:\n$e',
        Colors.red,
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
      _showMessage(
        'PDF link is not available.',
        Colors.red,
      );
      return;
    }

    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri == null) {
      _showMessage(
        'Invalid PDF link.',
        Colors.red,
      );
      return;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open PDF.',
          Colors.red,
        );
      }
    } catch (e) {
      _showMessage(
        'Unable to open PDF:\n$e',
        Colors.red,
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
    if (url.trim().isEmpty) {
      _showMessage(
        'Image link is not available.',
        Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(15),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (
                    context,
                    child,
                    progress,
                  ) {
                    if (progress == null) {
                      return child;
                    }

                    return const SizedBox(
                      height: 400,
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
                      height: 400,
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
                right: 5,
                top: 5,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
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
  // BUILD UPLOADED MATERIAL CARD
  // ============================================================

  Widget _buildUploadedMaterialCard(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? {};

    final String title = (data['title'] ?? 'Untitled Notes').toString();

    final String description = (data['description'] ?? '').toString();

    final String semester = (data['semester'] ?? '').toString();

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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TITLE ROW
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    hasPdf ? Icons.picture_as_pdf : Icons.image,
                    color: hasPdf ? Colors.red : Colors.green,
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
                    tooltip: 'Delete material',
                    padding: EdgeInsets.zero,
                    onPressed: _isUploading
                        ? null
                        : () => _deleteNote(
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

            // ==================================================
            // DESCRIPTION
            // ==================================================

            if (description.trim().isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // UPLOAD DATE
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

                const Spacer(),

                // PDF indicator
                if (hasPdf)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        6,
                      ),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (hasPdf && hasImage)
                  const SizedBox(
                    width: 5,
                  ),

                // Image indicator
                if (hasImage)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        6,
                      ),
                    ),
                    child: const Text(
                      'IMAGE',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // FILE DETAILS
            // ==================================================

            if (hasPdf)
              Container(
                padding: const EdgeInsets.all(
                  10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.04),
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
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        pdfName.isEmpty ? 'PDF File' : pdfName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    SizedBox(
                      width: 70,
                      height: 38,
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
                            horizontal: 5,
                          ),
                        ),
                        child: const Text(
                          'VIEW',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // IMAGE DETAILS
            // ==================================================

            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                      alpha: 0.04,
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
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          imageName.isEmpty ? 'Camera Image' : imageName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      SizedBox(
                        width: 70,
                        height: 38,
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
                              horizontal: 5,
                            ),
                          ),
                          child: const Text(
                            'VIEW',
                            style: TextStyle(
                              fontSize: 11,
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
      ),
    );
  }

  // ============================================================
  // SHOW MESSAGE
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
        duration: const Duration(
          seconds: 3,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();

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
          'Upload Study Notes',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    // ==================================================
                    // HEADER
                    // ==================================================

                    const Text(
                      'Upload Department Notes / E-Books',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'PDF notes and camera photos will be stored securely in Firebase.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // SEMESTER
                    // ==================================================

                    DropdownButtonFormField<String>(
                      initialValue: _selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Target Semester',
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
                          : (
                              value,
                            ) {
                              if (value != null) {
                                setState(
                                  () {
                                    _selectedSemester = value;
                                  },
                                );
                              }
                            },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    TextField(
                      controller: _titleController,
                      enabled: !_isUploading,
                      decoration: const InputDecoration(
                        labelText: 'Notes Title',
                        hintText: 'e.g. Unit-1 Relational Algebra & SQL',
                        prefixIcon: Icon(
                          Icons.title,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    TextField(
                      controller: _descController,
                      enabled: !_isUploading,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Topic Details',
                        hintText: 'e.g. DBMS BCA-301 Full Lecture Notes',
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
                    // PDF BUTTON
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _selectPdf,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      label: Text(
                        _selectedPdfName ?? 'Attach PDF File',
                      ),
                    ),

                    // ==================================================
                    // PDF PREVIEW
                    // ==================================================

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
                            _selectedPdfName ?? 'PDF File',
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
                      height: 12,
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

                    // ==================================================
                    // IMAGE PREVIEW
                    // ==================================================

                    if (_selectedCameraImage != null)
                      Card(
                        margin: const EdgeInsets.only(
                          top: 10,
                        ),
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
                      height: 24,
                    ),

                    // ==================================================
                    // UPLOAD BUTTON
                    // ==================================================

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadNote,
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
                                Icons.cloud_upload,
                              ),
                        label: Text(
                          _isUploading
                              ? 'Uploading to Firebase...'
                              : 'Upload Study Material',
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
            // UPLOADED MATERIAL HEADER
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Uploaded Study Materials',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ==================================================
                // SEMESTER FILTER
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
                      onChanged: (value) {
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

            // ==================================================
            // FIRESTORE LIST
            // ==================================================

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection(
                    'study_notes',
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
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

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

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

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
                            'Unable to load uploaded materials.',
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

                // ------------------------------------------------
                // GET DOCUMENTS
                // ------------------------------------------------

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

                // ------------------------------------------------
                // SORT NEWEST FIRST
                // ------------------------------------------------

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

                // ------------------------------------------------
                // EMPTY
                // ------------------------------------------------

                if (docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.library_books_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            _filterSemester == 'All'
                                ? 'No study materials uploaded yet.'
                                : 'No materials uploaded for $_filterSemester.',
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

                // ------------------------------------------------
                // LIST
                // ------------------------------------------------

                return Column(
                  children: docs.map(
                    (
                      doc,
                    ) {
                      return _buildUploadedMaterialCard(
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
