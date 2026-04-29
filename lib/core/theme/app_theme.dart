import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

/// Backward-compat shim. Older code imports `AppColors.primary` etc. We keep
/// those names but point them at the new dark tokens so existing callers
/// don't break while we migrate screens to AppTokens directly.
class AppColors {
  AppColors._();

  static const Color primary       = AppTokens.blue;
  static const Color primaryDark   = AppTokens.blueL;
  static const Color background    = AppTokens.bg;
  static const Color surface       = AppTokens.bgCard;
  static const Color dark          = AppTokens.bg;
  static const Color textPrimary   = AppTokens.tp;
  static const Color textSecondary = AppTokens.ts;
  static const Color error         = AppTokens.red;
  static const Color success       = AppTokens.teal;
  static const Color warning       = AppTokens.amber;
  static const Color border        = AppTokens.border;

  static const Color active    = AppTokens.teal;
  static const Color inactive  = AppTokens.amber;
  static const Color suspended = AppTokens.red;
}

class AppTheme {
  AppTheme._();

  static TextTheme get _baseTextTheme => GoogleFonts.plusJakartaSansTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness:   Brightness.dark,
    scaffoldBackgroundColor: AppTokens.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor:  AppTokens.blue,
      brightness: Brightness.dark,
      primary:    AppTokens.blue,
      surface:    AppTokens.bgCard,
      error:      AppTokens.red,
      onPrimary:  Colors.white,
      onSurface:  AppTokens.tp,
    ),
    textTheme: _baseTextTheme.copyWith(
      displayLarge:  GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: AppTokens.tp),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTokens.tp),
      titleLarge:    GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppTokens.tp),
      titleMedium:   GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTokens.tp),
      bodyLarge:     GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTokens.tp),
      bodyMedium:    GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: AppTokens.ts),
      bodySmall:     GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, color: AppTokens.ts),
      labelLarge:    GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.bgEl,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppTokens.tm, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:         _border(AppTokens.border),
      enabledBorder:  _border(AppTokens.border),
      focusedBorder:  _border(AppTokens.blue, 1.6),
      errorBorder:    _border(AppTokens.red),
      focusedErrorBorder: _border(AppTokens.red, 1.6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.blue,
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 50),
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
        textStyle:       GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        elevation:       0,
      ),
    ),
    cardTheme: CardThemeData(
      color:    AppTokens.bgCard,
      elevation: 0,
      shape:    RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rLg),
        side:         const BorderSide(color: AppTokens.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppTokens.bg,
      surfaceTintColor: AppTokens.bg,
      elevation:        0,
      centerTitle:      false,
      titleTextStyle:   GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTokens.tp),
      iconTheme:        const IconThemeData(color: AppTokens.tp),
    ),
    dividerTheme: const DividerThemeData(color: AppTokens.border, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTokens.bgEl,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: AppTokens.tp, fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMd)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static OutlineInputBorder _border(Color c, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTokens.rMd),
    borderSide:   BorderSide(color: c, width: width),
  );
}
