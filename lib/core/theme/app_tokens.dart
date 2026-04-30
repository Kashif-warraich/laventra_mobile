import 'package:flutter/material.dart';

/// Design tokens for Laventra. Mirrors the `T={...}` palette in the Claude
/// design — keep names short to read in widget code (`T.bg`, `T.blue`).
///
/// Two import shortcuts exist:
///   import '...app_tokens.dart' show T;            // most code
///   import '...app_tokens.dart' show AppTokens;    // for reflective use
class AppTokens {
  AppTokens._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color bg     = Color(0xFF080F1E);
  static const Color bgCard = Color(0xFF0F1B2D);
  static const Color bgEl   = Color(0xFF162236);

  // ── Borders ─────────────────────────────────────────────────────────────
  static const Color border  = Color(0xFF1C2F47);
  static const Color borderL = Color(0xFF243D5C);

  // ── Brand + accents ─────────────────────────────────────────────────────
  static const Color blue   = Color(0xFF2B7FFF);
  static const Color blueL  = Color(0xFF5B9FFF);
  static const Color teal   = Color(0xFF00C896);
  static const Color tealL  = Color(0xFF00D4AA);
  static const Color amber  = Color(0xFFF5A623);
  static const Color red    = Color(0xFFFF4D6A);
  static const Color purple = Color(0xFF9B7FFF);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color tp = Color(0xFFEEF3FF); // primary text
  static const Color ts = Color(0xFF6A8FAD); // secondary text
  static const Color tm = Color(0xFF3D5570); // muted

  // ── Status convenience ──────────────────────────────────────────────────
  static const Color statusSuccess = teal;
  static const Color statusError   = red;
  static const Color statusAlert   = amber;
  static const Color statusInfo    = blue;

  // ── Radii / spacings used everywhere ───────────────────────────────────
  static const double rSm  = 8;
  static const double rMd  = 12;
  static const double rLg  = 16;
  static const double rXl  = 20;
}

/// Short alias — design code reads `T.blue` etc., we keep that ergonomic.
typedef T = AppTokens;
