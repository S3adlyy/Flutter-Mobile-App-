import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/signup_page.dart';
import '../screens/welcome_page.dart';
import '../screens/admin_dashboard.dart';
import '../screens/employee_home_page.dart';

/// The single gate every screen navigation funnels through after login
/// or app launch:
///
///   unknown          -> loading spinner
///   unauthenticated   -> WelcomePage (Login/Register)
///   authenticated     -> role == 'admin'    -> AdminDashboard
///                        role == 'employee' -> EmployeeHomePage
///
/// Put this as the `home:` of MaterialApp so every cold start and every
/// login re-evaluates the role fresh from Firestore (via AuthProvider),
/// instead of trusting whatever was true last time.
class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case AuthStatus.unauthenticated:
        return const WelcomePage();

      case AuthStatus.authenticated:
        final user = auth.userModel;

        if (user == null) {
          // Auth succeeded but the Firestore doc hasn't loaded yet
          // (or is missing) — show a spinner rather than guessing a role.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user.isAdmin) {
          return const AdminDashboard();
        }
        return const EmployeeHomePage();
    }
  }
}