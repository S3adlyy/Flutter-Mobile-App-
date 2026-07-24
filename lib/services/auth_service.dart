import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Handles Firebase Authentication only. All Firestore user-document
/// logic is delegated to [UserRepository] so this class stays focused.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  // google_sign_in v7+ is a singleton — GoogleSignIn() no longer exists.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  Future<void> _ensureGoogleReady() async {
    if (_googleSignInReady) return;
    // Must be called and awaited exactly once before any other method
    // on GoogleSignIn.instance. Safe to call lazily here on first use.
    await _googleSignIn.initialize();
    _googleSignInReady = true;
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Public sign-up path. Intentionally has NO `role` parameter —
  /// every account created through the app becomes an "employee".
  /// Admin accounts are never created here (see class doc / requirement #2).
  Future<String?> registerEmployee({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _userRepository.createEmployeeDocument(
        uid: result.user!.uid,
        name: name,
        email: email.trim(),
      );

      await result.user!.sendEmailVerification();

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Signs in with Google. If this is the user's first time signing in
  /// (no Firestore doc yet), a doc is created for them via the exact same
  /// path as normal sign-up: role is hard-coded to 'employee'. Google
  /// Sign-In can NEVER create an admin, same as registerEmployee().
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      // Triggers the account picker / Credential Manager sheet. In v7
      // this throws (GoogleSignInException) on cancel instead of
      // returning null like the old signIn() did.
      final googleUser = await _googleSignIn.authenticate();

      // .authentication is now a synchronous getter, and only carries an
      // idToken — that's all Firebase needs for signInWithCredential.
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;

      // First time this Google account has ever signed in? Create their
      // employee doc now, same rule as email/password sign-up.
      final existing = await _userRepository.getUser(user.uid);
      if (existing == null) {
        await _userRepository.createEmployeeDocument(
          uid: user.uid,
          name: user.displayName ?? 'New User',
          email: user.email ?? '',
        );
      }

      return null; // success
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return 'Google sign-in was cancelled.';
      }
      return 'Google sign-in failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  /// Looks up the current user's role from Firestore. Returns null if
  /// no document exists yet (shouldn't normally happen, but treat as
  /// "not authorized for anything" rather than guessing a default here).
  Future<String?> getUserRole(String uid) {
    return _userRepository.getUserRole(uid);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _userRepository.getUser(uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    // Also sign out of the Google session itself, otherwise the account
    // picker can be skipped next time. isSignedIn() was removed in v7,
    // so just call signOut() directly — it's a no-op if nothing is signed in.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore — not signed in with Google, or already signed out.
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

}