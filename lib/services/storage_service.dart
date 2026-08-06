import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload PDF Notes or Document Attachments
  Future<String> uploadPdfNote({
    required File file,
    required String fileName,
    required String folder,
  }) async {
    try {
      Reference ref = _storage.ref().child(
          'bca_dept/$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload Raw Bytes for Web/In-memory
  Future<String> uploadBytes({
    required List<int> bytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      Reference ref = _storage.ref().child(
          'bca_dept/$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      UploadTask uploadTask = ref.putData(Uint8List.fromList(bytes));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}
