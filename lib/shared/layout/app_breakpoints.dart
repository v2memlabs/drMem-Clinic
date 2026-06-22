/// Responsive layout breakpoint sabitleri — yalnızca UI genişlik kararları.
abstract final class AppBreakpoints {
  /// AppShell geniş sidebar (mevcut davranış).
  static const double sidebarExpanded = 900;

  /// Dar / telefon benzeri içerik.
  static const double compact = 0;

  /// Tablet dikey ve küçük genişlikler.
  static const double tablet = 600;

  /// Tablet yatay / küçük laptop içerik alanı.
  static const double tabletLandscape = 840;

  /// Windows desktop ve geniş tablet yatay.
  static const double desktop = 1200;

  /// Ultra geniş monitörler.
  static const double wideDesktop = 1600;

  /// PageHeader dar düzen.
  static const double pageHeaderStack = 560;

  /// FilterBar trailing sağ sütun (tablet+ arama ile aynı satır).
  static const double filterSideTrailing = tablet;

  /// FilterBar trailing alt satır.
  static const double filterStackTrailing = 720;

  /// Detay ekranı iki kolon section.
  static const double detailTwoColumn = 880;

  /// İçerik max genişlikleri.
  static const double listMaxWidth = 1080;
  static const double detailMaxWidth = 960;
  static const double detailWideMaxWidth = 1120;
  static const double formStandardMaxWidth = 760;
  static const double formLongMaxWidth = 800;
  static const double dashboardMaxWidth = 1200;

  /// Dashboard kart ızgarası.
  static const double dashboardGrid4 = 1400;
  static const double dashboardGrid3 = 1040;
  static const double dashboardGrid2 = 560;
}
