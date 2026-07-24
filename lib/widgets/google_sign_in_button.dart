import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A neutral (white/outlined) button for "Continue with Google", meant to
/// sit either on the gradient hero (WelcomePage) or on the white sheet
/// (LoginPage). Uses a simple "G" glyph placeholder — swap the `child`
/// icon for a proper Google "G" logo asset (assets/google_logo.png) if
/// you want the official mark.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.taupe.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.amber,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder "G" — replace with Image.asset('assets/google_logo.png')
            // for the official Google logo if desired.
            Container(
              height: 20,
              width: 20,
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: AppText.button.copyWith(color: AppColors.ink, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}