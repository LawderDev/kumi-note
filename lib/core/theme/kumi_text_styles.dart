import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kumi_colors.dart';

/// Kumi typography system using Plus Jakarta Sans
class KumiTextStyles {
  const KumiTextStyles._();

  static final TextStyle headlineL = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: KumiColors.textPrimary,
    height: 1.2,
  );

  static final TextStyle headlineM = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: KumiColors.textPrimary,
    height: 1.3,
  );

  static final TextStyle headlineS = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: KumiColors.textPrimary,
    height: 1.4,
  );

  static final TextStyle bodyL = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KumiColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyM = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KumiColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyS = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KumiColors.textSecondary,
    height: 1.5,
  );

  static final TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: KumiColors.textSecondary,
    height: 1.5,
  );
}
