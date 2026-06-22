import 'package:flutter/material.dart';

/// Premium soft shadow token'ları.
///
/// [CardTheme] elevation ile birlikte veya doğrudan [Container] dekorasyonunda
/// (component v2) kullanılabilir.
abstract final class AppShadows {
  static const Color _shadowColor = Color(0x1A0D2137);

  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x0D0D2137),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// Login giriş kartı ile uyumlu orta gölge.
  static List<BoxShadow> get card => const [
        BoxShadow(
          color: _shadowColor,
          blurRadius: 12,
          offset: Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  /// Liste/detay üst kartları — login elevatedCard ile aynı dil.
  static List<BoxShadow> get premiumCard => elevatedCard;

  static List<BoxShadow> get elevatedCard => const [
        BoxShadow(
          color: Color(0x240D2137),
          blurRadius: 20,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  /// Theme [CardThemeData.shadowColor] için tek renk gölge ipucu.
  static Color get cardShadowColor => _shadowColor.withValues(alpha: 0.08);
}
