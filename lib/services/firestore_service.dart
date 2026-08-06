import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/subject_model.dart';
import '../models/notice_model.dart';
import '../models/note_model.dart';

import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER APPROVALS & FACULTY MANAGEMENT ---
  Stream<List<UserModel>> getPendingRegistrations(String role) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateUserStatus(String uid, String newStatus) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'status': newStatus});
  }

  Stream<List<UserModel>> getFacultyList() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleFaculty)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<UserModel>> getStudentListBySemester(String semester) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteFaculty(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  // --- SUBJECT MANAGEMENT (Semesters 1 to 6) ---
  Stream<List<SubjectModel>> getSubjectsBySemester(String semester) {
    return _db
        .collection(AppConstants.subjectsCollection)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSubject(SubjectModel subject) async {
    await _db.collection(AppConstants.subjectsCollection).add(subject.toMap());
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db
        .collection(AppConstants.subjectsCollection)
        .doc(subject.id)
        .update(subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection(AppConstants.subjectsCollection).doc(id).delete();
  }

  // --- NOTICES ---
  Stream<List<NoticeModel>> getNotices() {
    return _db
        .collection(AppConstants.noticesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> uploadNotice(NoticeModel notice) async {
    await _db.collection(AppConstants.noticesCollection).add(notice.toMap());
  }

  // --- NOTES (PDF Uploads) ---
  Stream<List<NoteModel>> getNotesBySemester(String semester) {
    return _db
        .collection(AppConstants.notesCollection)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NoteModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> uploadNote(NoteModel note) async {
    await _db.collection(AppConstants.notesCollection).add(note.toMap());
  }

  // --- ATTENDANCE ---
  Future<void> recordAttendance(AttendanceModel attendance) async {
    await _db
        .collection(AppConstants.attendanceCollection)
        .add(attendance.toMap());
  }

  Stream<List<AttendanceModel>> getAttendanceBySemester(
      String semester, String subjectCode) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('semester', isEqualTo: semester)
        .where('subjectCode', isEqualTo: subjectCode)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- INTERNAL MARKS ---
  Future<void> uploadInternalMark(MarksModel mark) async {
    await _db.collection(AppConstants.marksCollection).add(mark.toMap());
  }

  Stream<List<MarksModel>> getStudentMarks(String studentId) {
    return _db
        .collection(AppConstants.marksCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MarksModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MarksModel>> getMarksBySubjectAndSemester(
      String subjectCode, String semester) {
    return _db
        .collection(AppConstants.marksCollection)
        .where('subjectCode', isEqualTo: subjectCode)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MarksModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
