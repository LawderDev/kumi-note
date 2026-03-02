import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kumi Chat theme definition.
///
/// Defines all colors, typography, and design tokens for the
/// Kumi Chat interface.
class KumiTheme {
  // Private constructor to prevent instantiation
  KumiTheme._();

  // ============ Colors ============

  /// Cream color - main background color
  /// #FFFDF5 - Warm, friendly, and easy on the eyes
  static const Color cream = Color(0xFFFFFDF5);

  /// Orange color - accent and interactive elements
  /// #D35400 - Energetic and warm, inspired by Shiba's fur
  static const Color orange = Color(0xFFD35400);

  /// Anthracite Gray - text and secondary elements
  /// #2D2D2D - Dark but not pure black for better readability
  static const Color anthraciteGray = Color(0xFF2D2D2D);

  /// Light gray for subtle dividers and borders
  static const Color lightGray = Color(0xFFE8E8E8);

  /// Soft gray for disabled states
  static const Color disabledGray = Color(0xFFC4C4C4);

  /// Success green for confirmatory messages
  static const Color successGreen = Color(0xFF27AE60);

  /// Error red for error messages
  static const Color errorRed = Color(0xFFE74C3C);

  // ============ Text Styles ============

  /// Title text style - for page titles
  static TextStyle get titleStyle => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: anthraciteGray,
  );

  /// Subtitle text style - for section headers
  static TextStyle get subtitleStyle => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: anthraciteGray,
  );

  /// Body text style - for regular content
  static TextStyle get bodyStyle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: anthraciteGray,
    height: 1.5,
  );

  /// Small text style - for secondary information
  static TextStyle get smallStyle => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: anthraciteGray,
  );

  /// Chat message text style
  static TextStyle get chatMessageStyle => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: anthraciteGray,
    height: 1.4,
  );

  /// Button text style
  static TextStyle get buttonStyle => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ============ Border Radius ============

  /// Small border radius (4dp)
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(4));

  /// Medium border radius (12dp) - used for chat bubbles
  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(12),
  );

  /// Large border radius (24dp) - used for main containers
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(24));

  /// Full circular border radius
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(999));

  // ============ Shadows ============

  /// Subtle shadow for cards and bubbles
  static const BoxShadow subtleShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  /// Medium shadow for modals and overlays
  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  /// Strong shadow for floating elements
  static const BoxShadow strongShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  // ============ Spacing ============

  /// Extra small spacing (4dp)
  static const double spacingXS = 4;

  /// Small spacing (8dp)
  static const double spacingS = 8;

  /// Medium spacing (16dp)
  static const double spacingM = 16;

  /// Large spacing (24dp)
  static const double spacingL = 24;

  /// Extra large spacing (32dp)
  static const double spacingXL = 32;
}
