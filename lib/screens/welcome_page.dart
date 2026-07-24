import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/role_guard.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _continueWithGoogle(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Google sign-in failed'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleGuard()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Logo badge
                Container(
                  height: 84,
                  width: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.amber, size: 44),
                ),
                const SizedBox(height: 24),
                Text('Mobile App', style: AppText.displayOnGradient),
                const SizedBox(height: 8),
                Text(
                  'Sign in to keep going, or create\nan account to get started',
                  textAlign: TextAlign.center,
                  style: AppText.subtitleOnGradient,
                ),
                const Spacer(flex: 4),

                // Primary: Login
                GradientButton.light(
                  label: 'Login',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                ),
                const SizedBox(height: 14),

                // Secondary: Register (outlined on white sheet look)
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: AppText.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.4))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppText.subtitleOnGradient),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.4))),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign-In
                GoogleSignInButton(
                  isLoading: auth.isLoading,
                  onPressed: () => _continueWithGoogle(context),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}