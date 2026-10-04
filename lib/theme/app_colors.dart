import 'package:flutter/material.dart';

/// Paleta de colores del sistema de diseño.
class AppColors {
  AppColors._();

  // ── Modo Oscuro ───────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D1517);
  static const Color darkPanel = Color(0xFF142225);
  static const Color darkSurface = Color(0xFF1A2D31);
  static const Color darkBorder = Color(0xFF2A3F44);

  // ── Modo Claro ────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF2F6F5);
  static const Color lightPanel = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFA);
  static const Color lightBorder = Color(0xFFD8E0DE);

  // ── Acentos ───────────────────────────────────────────────────────
  static const Color turquesa = Color(0xFF28D6BD);
  static const Color turquesaOscuro = Color(0xFF087E70);
  static const Color ambar = Color(0xFFF6BB57);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color azul = Color(0xFF71A7FF);

  // ── Semáforo de recomendación ─────────────────────────────────────
  static const Color semaforoVerde = Color(0xFF28D6BD);
  static const Color semaforoAmarillo = Color(0xFFF6BB57);
  static const Color semaforoRojo = Color(0xFFFF6B6B);

  // ── Texto oscuro ──────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFE8F0EE);
  static const Color darkTextSecondary = Color(0xFF9DB5B0);
  static const Color darkTextMuted = Color(0xFF5E7A74);

  // ── Texto claro ───────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF1A2D31);
  static const Color lightTextSecondary = Color(0xFF4A6560);
  static const Color lightTextMuted = Color(0xFF8AA09B);
}
