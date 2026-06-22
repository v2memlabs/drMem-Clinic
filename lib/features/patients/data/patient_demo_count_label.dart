import '../../../core/product/demo_freemium_config.dart';

/// Ayarlar demo kartı — hasta sayısı gösterim metni (enforcement iddiası yok).
abstract final class PatientDemoCountLabel {
  static String format({required int count, required int limit}) {
    return '$count / $limit demo limit';
  }

  static String limitNote({required int count, required int limit}) {
    if (count > limit) {
      return '${DemoFreemiumConfig.patientLimitNote} '
          'Limit uygulaması sonraki SaaS fazında etkinleşecektir.';
    }
    return DemoFreemiumConfig.patientLimitNote;
  }
}
