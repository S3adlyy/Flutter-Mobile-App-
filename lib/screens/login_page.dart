import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_page.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/role_guard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    // RoleGuard re-checks the freshly loaded role and routes to
    // AdminDashboard or EmployeeHomePage accordingly.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleGuard()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Login to continue where you left off',
      onBack: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Email', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: 'you@example.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            Text('Password', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.taupe,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            GradientButton(
              label: 'Login',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _login,
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: AppText.body),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: Text(
                    'Register',
                    style: AppText.body.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}