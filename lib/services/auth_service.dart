import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Email and Password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (res.user != null) {
        DocumentSnapshot doc = await _db
            .collection(AppConstants.usersCollection)
            .doc(res.user!.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register User
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? rollNo,
    String? employeeId,
    String? semester,
    String? designation,
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Default status for HOD is approved; Faculty & Student require approval by HOD
      String initialStatus = (role == AppConstants.roleHOD)
          ? AppConstants.statusApproved
          : AppConstants.statusPending;

      UserModel user = UserModel(
        uid: res.user!.uid,
        name: name,
        email: email,
        role: role,
        status: initialStatus,
        phone: phone,
        rollNo: rollNo,
        employeeId: employeeId,
        semester: semester,
        designation: designation,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Get User Profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
