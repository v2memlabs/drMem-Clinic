import 'package:flutter/material.dart';

/// drMem Clinic renk token'ları.
///
/// Turkuaz + lacivert marka yönü korunur. Ekranlar bu sınıfa toplu migrate
/// edilmez; [AppTheme] ve sonraki premium component fazları referans alır.
abstract final class AppColors {
  // —— Marka (mevcut palet) ——
  /// Ana klinik teal (#05595B) — primary, CTA, aktif vurgu tabanı.
  static const Color primaryDeepTeal = Color(0xFF05595B);

  /// Turkuaz vurgu (#00838F) — PDF antet ile uyumlu accent.
  static const Color accentTurquoise = Color(0xFF00838F);

  /// Lacivert vurgu (#1565C0) — başlık/ikincil marka tonu.
  static const Color navy = Color(0xFF1565C0);

  /// Sidebar için koyu lacivert (Faz 3 AppShell; theme'de tertiary container).
  static const Color navyDark = Color(0xFF0D2137);

  /// Login sol panel ile aynı aile — AppShell sidebar arka planı.
  static LinearGradient get sidebarBrandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          navyDark,
          navyDark,
          primaryDeepTeal.withValues(alpha: 0.35),
        ],
        stops: const [0, 0.55, 1],
      );

  // —— Yüzeyler ——
  static const Color backgroundSoft = Color(0xFFF6F8F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderSoft = Color(0xFFE2E8EC);

  // —— Metin ——
  static const Color textPrimary = Color(0xDE000000); // ~black87
  static const Color textSecondary = Color(0xFF616161);

  // —— Semantic (chip / status / uyarı — ileriki fazlar) ——
  static const Color success = Color(0xFF2E7D52);
  static const Color successSurface = Color(0xFFD7F0E3);
  static const Color warning = Color(0xFF8A4B00);
  static const Color warningSurface = Color(0xFFFFE8CC);
  static const Color danger = Color(0xFFB71C1C);
  static const Color dangerSurface = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoSurface = Color(0xFFE3F2FD);

  /// Hafif dolgu input alanı (light).
  static const Color inputFillLight = Color(0xFFFAFBFC);
}
