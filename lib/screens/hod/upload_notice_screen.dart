import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  // Camera image
  File? _selectedCameraImage;

  String? _selectedImageName;

  // PDF
  File? _selectedPdfFile;

  String? _selectedPdfName;

  bool _isUploading = false;

  // ============================================================
  // SEMESTER 1 - 6
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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedCameraImage = File(image.path);

        _selectedImageName = image.name;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // PICK PDF
  // ============================================================

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final pickedFile = result.files.single;

      setState(() {
        _selectedPdfFile = File(pickedFile.path!);

        _selectedPdfName = pickedFile.name;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF selected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF selection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // REMOVE CAMERA IMAGE
  // ============================================================

  void _removeImage() {
    setState(() {
      _selectedCameraImage = null;
      _selectedImageName = null;
    });
  }

  // ============================================================
  // REMOVE PDF
  // ============================================================

  void _removePdf() {
    setState(() {
      _selectedPdfFile = null;
      _selectedPdfName = null;
    });
  }

  // ============================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadImage(
    String noticeId,
  ) async {
    if (_selectedCameraImage == null) {
      return null;
    }

    final fileName = 'notice_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final Reference storageRef =
        _storage.ref().child('notice_images').child(noticeId).child(fileName);

    await storageRef.putFile(
      _selectedCameraImage!,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD PDF TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadPdf(
    String noticeId,
  ) async {
    if (_selectedPdfFile == null) {
      return null;
    }

    final safeFileName = _selectedPdfName ?? 'notice_document.pdf';

    final Reference storageRef =
        _storage.ref().child('notice_pdfs').child(noticeId).child(safeFileName);

    await storageRef.putFile(
      _selectedPdfFile!,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // PUBLISH NOTICE
  // ============================================================

  Future<void> _publishNotice() async {
    final title = _titleController.text.trim();

    final content = _contentController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      _showError(
        'Please enter notice title',
      );
      return;
    }

    if (content.isEmpty) {
      _showError(
        'Please enter notice content',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ========================================================
      // CREATE FIRESTORE DOCUMENT FIRST
      // ========================================================

      final noticeRef = _firestore.collection('notices').doc();

      final noticeId = noticeRef.id;

      // ========================================================
      // UPLOAD IMAGE
      // ========================================================

      String? imageUrl;

      if (_selectedCameraImage != null) {
        imageUrl = await _uploadImage(noticeId);
      }

      // ========================================================
      // UPLOAD PDF
      // ========================================================

      String? pdfUrl;

      if (_selectedPdfFile != null) {
        pdfUrl = await _uploadPdf(noticeId);
      }

      // ========================================================
      // SAVE NOTICE TO FIRESTORE
      // ========================================================

      await noticeRef.set({
        'noticeId': noticeId,
        'title': title,
        'content': content,
        'targetAudience': _targetAudience,
        'semester': _selectedSemester,
        'department': 'BCA',
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'pdfName': _selectedPdfName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'published',
        'createdBy': 'department',
        'createdByRole': 'hod',
      });

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Department Notice Published Successfully!',
          ),
          backgroundColor: Colors.green,
        ),
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
      });

      Navigator.pop(context);
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
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Department Notice',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
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

                    const SizedBox(height: 4),

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
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        hintText: 'e.g. Mid-Sem Examination Schedule 2026',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // TARGET AUDIENCE
                    // ==================================================

                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      decoration: const InputDecoration(
                        labelText: 'Audience / Target',
                        prefixIcon: Icon(Icons.people),
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
                                setState(() {
                                  _targetAudience = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // SEMESTER 1 - 6
                    // ==================================================

                    DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Select Semester',
                        prefixIcon: Icon(
                          Icons.school_outlined,
                        ),
                      ),
                      items: _semesters
                          .map(
                            (semester) => DropdownMenuItem<String>(
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
                                setState(() {
                                  _selectedSemester = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // CONTENT
                    // ==================================================

                    TextField(
                      controller: _contentController,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.photo_camera,
                                    size: 20,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _selectedImageName ?? 'Captured Photo',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _removeImage,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // PDF ATTACHMENT
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

                    // ==================================================
                    // PDF SELECTED PREVIEW
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
                            _selectedPdfName ?? 'PDF Document',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text(
                            'PDF ready to upload',
                          ),
                          trailing: IconButton(
                            onPressed: _removePdf,
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
                    // PUBLISH
                    // ==================================================

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _publishNotice,
                        icon: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
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
                              ? 'Uploading...'
                              : 'Publish & Broadcast Notice',
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
}
