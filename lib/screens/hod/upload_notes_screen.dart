import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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
  // SELECT PDF
  // ============================================================

  Future<void> _selectPdf() async {
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
          content: Text('PDF selection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
  // REMOVE PDF
  // ============================================================

  void _removePdf() {
    setState(() {
      _selectedPdfFile = null;
      _selectedPdfName = null;
    });
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
  // UPLOAD PDF TO STORAGE
  // ============================================================

  Future<String?> _uploadPdf(
    String noteId,
  ) async {
    if (_selectedPdfFile == null) {
      return null;
    }

    final fileName = _selectedPdfName ?? 'note.pdf';

    final storageRef =
        _storage.ref().child('study_notes').child(noteId).child(fileName);

    await storageRef.putFile(
      _selectedPdfFile!,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD CAMERA IMAGE TO STORAGE
  // ============================================================

  Future<String?> _uploadImage(
    String noteId,
  ) async {
    if (_selectedCameraImage == null) {
      return null;
    }

    final fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storageRef =
        _storage.ref().child('study_notes').child(noteId).child(fileName);

    await storageRef.putFile(
      _selectedCameraImage!,
    );

    return await storageRef.getDownloadURL();
  }

  // ============================================================
  // UPLOAD NOTE
  // ============================================================

  Future<void> _uploadNote() async {
    final title = _titleController.text.trim();

    final description = _descController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      _showError(
        'Please enter note title',
      );
      return;
    }

    if (description.isEmpty) {
      _showError(
        'Please enter subject/topic details',
      );
      return;
    }

    if (_selectedPdfFile == null && _selectedCameraImage == null) {
      _showError(
        'Please attach a PDF or capture a photo',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ========================================================
      // CREATE FIRESTORE DOCUMENT ID
      // ========================================================

      final noteRef = _firestore.collection('study_notes').doc();

      final noteId = noteRef.id;

      // ========================================================
      // UPLOAD PDF
      // ========================================================

      String? pdfUrl;

      if (_selectedPdfFile != null) {
        pdfUrl = await _uploadPdf(noteId);
      }

      // ========================================================
      // UPLOAD CAMERA IMAGE
      // ========================================================

      String? imageUrl;

      if (_selectedCameraImage != null) {
        imageUrl = await _uploadImage(noteId);
      }

      // ========================================================
      // SAVE DATA TO FIRESTORE
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

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Study material uploaded successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _descController.clear();

      setState(() {
        _selectedPdfFile = null;
        _selectedPdfName = null;

        _selectedCameraImage = null;
        _selectedImageName = null;

        _selectedSemester = 'Semester 1';
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showError(
        'Upload failed:\n$e',
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
    _descController.dispose();

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
          'Upload Study Notes',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  'PDF notes and camera photos will be stored in Firebase.',
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
                  value: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Target Semester',
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
                // TITLE
                // ==================================================

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notes Title',
                    hintText: 'e.g. Unit-1 Relational Algebra & SQL',
                    prefixIcon: Icon(Icons.title),
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
                        onPressed: _removePdf,
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
                // CAMERA BUTTON
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
                            onPressed: _removeImage,
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
                      _isUploading ? 'Uploading...' : 'Upload Study Material',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
