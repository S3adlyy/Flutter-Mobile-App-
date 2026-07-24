import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Single source of truth for "who is logged in and what is their role"
/// for the whole widget tree. Screens read this instead of calling
/// FirebaseAuth/Firestore directly, so role checks stay consistent
/// everywhere (RoleGuard, admin buttons, etc all read from here).
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  UserModel? userModel;
  String? errorMessage;
  bool isLoading = false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  bool get isAdmin => userModel?.isAdmin ?? false;
  bool get isEmployee => userModel?.isEmployee ?? false;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      status = AuthStatus.unauthenticated;
      userModel = null;
      notifyListeners();
      return;
    }
    await _loadUserModel(user.uid);
  }

  Future<void> _loadUserModel(String uid) async {
    userModel = await _authService.getCurrentUserModel();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await _authService.registerEmployee(
      name: name,
      email: email,
      password: password,
    );

    isLoading = false;
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }

    // Auth state listener will pick up the new user and load their model,
    // but we also load eagerly here so navigation can happen immediately.
    final uid = _authService.currentUser!.uid;
    await _loadUserModel(uid);
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await _authService.loginUser(email: email, password: password);

    isLoading = false;
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }

    final uid = _authService.currentUser!.uid;
    await _loadUserModel(uid);
    return true;
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await _authService.signInWithGoogle();

    isLoading = false;
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return false;
    }

    final uid = _authService.currentUser!.uid;
    await _loadUserModel(uid);
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    userModel = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}