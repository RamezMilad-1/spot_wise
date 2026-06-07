import 'package:flutter/material.dart';

/// Lagoon brand palette — the single source of truth for color in SpotWise.
///
/// Teal = trust / maps / water. Coral = warmth / discovery / calls-to-action.
/// Amber = ratings & highlights. Designed for a calm light mode and a deep,
/// legible dark mode.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color teal = Color(0xFF0E7C7B); // primary
  static const Color tealDark = Color(0xFF0A5C5B);
  static const Color tealLight = Color(0xFF3FA9A6);
  static const Color tealMist = Color(0xFFD7EEEC);

  static const Color coral = Color(0xFFFF6F5E); // accent / CTA
  static const Color coralDark = Color(0xFFE85544);
  static const Color coralMist = Color(0xFFFFE2DC);

  static const Color amber = Color(0xFFFFB454); // ratings / highlights

  // ── Neutrals (light) ──────────────────────────────────────────────────────
  static const Color cream = Color(0xFFFBF8F3); // app background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1EEE8);
  static const Color ink = Color(0xFF13232B); // primary text
  static const Color inkSoft = Color(0xFF4A5A62); // secondary text
  static const Color inkFaint = Color(0xFF8A98A0); // hints / disabled
  static const Color border = Color(0xFFE6E1D8);

  // ── Neutrals (dark) ───────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0E1A1F);
  static const Color darkSurface = Color(0xFF152A30);
  static const Color darkSurfaceAlt = Color(0xFF1C353C);
  static const Color darkInk = Color(0xFFEAF1F2);
  static const Color darkInkSoft = Color(0xFFAFC2C5);
  static const Color darkInkFaint = Color(0xFF6E8A90);
  static const Color darkBorder = Color(0xFF24454D);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2B9D6E);
  static const Color warning = Color(0xFFE8A317);
  static const Color danger = Color(0xFFE0533D);
  static const Color info = Color(0xFF2D8CCB);
  static const Color star = amber;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient lagoonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, tealLight],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, amber],
  );

  /// Soft scrim used over photos so white text stays legible.
  static const LinearGradient photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000)],
    stops: [0.45, 1.0],
  );
}
