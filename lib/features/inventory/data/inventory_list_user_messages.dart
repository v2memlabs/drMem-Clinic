import 'inventory_repository_failure.dart';

abstract final class InventoryListUserMessages {
  static const String loading = 'Stok kayıtları yükleniyor…';
  static const String errorTitle = 'Stok kayıtları yüklenemedi';
  static const String genericLoadFailure =
      'Stok kayıtları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(InventoryRepositoryFailure reason) {
    switch (reason) {
      case InventoryRepositoryFailure.forbidden:
        return 'Stok kayıtlarına erişim yetkiniz bulunmuyor.';
      case InventoryRepositoryFailure.noActiveTenant:
        return 'Stok kayıtları için aktif klinik oturumu gerekli.';
      case InventoryRepositoryFailure.notConfigured:
        return 'Stok kayıtları şu anda görüntülenemiyor.';
      case InventoryRepositoryFailure.network:
        return 'Stok kayıtları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case InventoryRepositoryFailure.notFound:
      case InventoryRepositoryFailure.invalidRow:
      case InventoryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
