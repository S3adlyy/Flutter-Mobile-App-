import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// The only place in the app allowed to talk to the `users` collection.
/// Keeping this isolated means if you ever change your data source
/// (e.g. add caching, switch backend), only this file changes.
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Creates the initial user document. Role is NOT a parameter here on
  /// purpose — see [createEmployeeDocument] and [createAdminDocumentManually]
  /// below. This keeps "what role a new doc gets" a deliberate decision
  /// made at the call site, not something passed in from a form.
  Future<void> createEmployeeDocument({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _usersRef.doc(uid).set({
      'name': name,
      'email': email,
      'role': 'employee', // hard-coded: normal sign-up can only ever create employees
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    });
  }

  /// Returns just the role string, used for the fast post-login check.
  Future<String?> getUserRole(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  Future<List<UserModel>> getAllEmployees() async {
    final snapshot =
    await _usersRef.where('role', isEqualTo: 'employee').get();
    return snapshot.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Promotes an employee to admin. This should ONLY ever be called from
  /// an admin-only screen — the Firestore security rules (see the rules
  /// file) are the real enforcement, this is just the app-side helper.
  Future<void> updateRole({
    required String targetUid,
    required String newRole,
  }) async {
    await _usersRef.doc(targetUid).update({'role': newRole});
  }
}