import 'package:flutter/material.dart';

/// Köşe yuvarlaklık token'ları — theme ve sonraki premium component'ler.
abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 20;

  /// Kart yüzeyi (premium yönde, önceki 12'den hafif artış).
  static const double card = 16;

  static const double dialog = 20;

  static BorderRadius get smallBorder => BorderRadius.circular(small);
  static BorderRadius get mediumBorder => BorderRadius.circular(medium);
  static BorderRadius get largeBorder => BorderRadius.circular(large);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get dialogBorder => BorderRadius.circular(dialog);
}
