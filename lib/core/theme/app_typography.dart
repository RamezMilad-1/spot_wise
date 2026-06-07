import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for SpotWise.
///
/// Headings use Plus Jakarta Sans (geometric, friendly). Body uses Inter
/// (highly legible). google_fonts fetches at runtime and falls back to the
/// platform font gracefully if the device is offline.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color ink, Color inkSoft) {
    final body = GoogleFonts.interTextTheme();
    TextStyle heading(double size, FontWeight weight, {double height = 1.15}) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          color: ink,
          height: height,
          letterSpacing: -0.2,
        );

    return body
        .copyWith(
          displayLarge: heading(40, FontWeight.w800),
          displayMedium: heading(34, FontWeight.w800),
          displaySmall: heading(28, FontWeight.w700),
          headlineMedium: heading(24, FontWeight.w700),
          headlineSmall: heading(20, FontWeight.w700),
          titleLarge: heading(18, FontWeight.w600),
          titleMedium: body.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          titleSmall: body.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          bodyLarge: body.bodyLarge?.copyWith(
            fontSize: 15,
            color: ink,
            height: 1.45,
          ),
          bodyMedium: body.bodyMedium?.copyWith(
            fontSize: 14,
            color: inkSoft,
            height: 1.45,
          ),
          bodySmall: body.bodySmall?.copyWith(
            fontSize: 12.5,
            color: inkSoft,
            height: 1.4,
          ),
          labelLarge: body.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          labelMedium: body.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: inkSoft,
          ),
        )
        .apply(bodyColor: ink, displayColor: ink);
  }
}
