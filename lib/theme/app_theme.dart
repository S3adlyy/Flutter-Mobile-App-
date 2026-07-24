import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the app's auth flow.
/// Palette: warm sunrise gradient + soft ink text on a cream-white sheet.
class AppColors {
  AppColors._();

  static const Color sunrise = Color(0xFFFF9142); // gradient start
  static const Color amber = Color(0xFFFF5F2E); // gradient end
  static const Color ink = Color(0xFF2B2118); // primary text
  static const Color taupe = Color(0xFF9C948C); // muted / secondary text
  static const Color sheet = Color(0xFFFFFFFF); // form panel background
  static const Color fieldFill = Color(0xFFF6F1EC); // input background
  static const Color coral = Color(0xFFE0483E); // errors

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunrise, amber],
  );
}

class AppText {
  AppText._();

  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
  );

  static TextStyle get displayOnGradient => GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
  );

  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.taupe,
  );

  static TextStyle get subtitleOnGradient => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white.withOpacity(0.85),
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
}

/// Rounded input decoration used across every auth form field.
InputDecoration authFieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: AppText.body.copyWith(color: AppColors.taupe),
    prefixIcon: Icon(icon, color: AppColors.taupe, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.coral, width: 1.2),
    ),
  );
}

/// The signature primary button: gradient fill, soft shadow, pill shape.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool light;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : light = false;

  /// White pill button meant to sit directly on the gradient hero
  /// (e.g. the welcome screen), with amber label text.
  const GradientButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : light = true;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: light || disabled ? null : AppColors.heroGradient,
        color: light
            ? Colors.white
            : (disabled ? AppColors.taupe.withOpacity(0.4) : null),
        borderRadius: BorderRadius.circular(16),
        boxShadow: disabled
            ? []
            : [
          BoxShadow(
            color: (light ? Colors.black : AppColors.amber)
                .withOpacity(light ? 0.10 : 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: light ? AppColors.amber : Colors.white,
                strokeWidth: 2.4,
              ),
            )
                : Text(
              label,
              style: AppText.button
                  .copyWith(color: light ? AppColors.amber : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}