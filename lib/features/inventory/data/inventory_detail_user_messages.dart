import 'inventory_repository_failure.dart';

abstract final class InventoryDetailUserMessages {
  static const String loading = 'Stok kartı yükleniyor…';
  static const String notFoundTitle = 'Stok kartı bulunamadı';
  static const String notFoundDescription =
      'Kayıt silinmiş veya erişim yetkiniz değişmiş olabilir.';
  static const String errorTitle = 'Stok kartı yüklenemedi';
  static const String genericLoadFailure =
      'Stok detayı yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(InventoryRepositoryFailure reason) {
    switch (reason) {
      case InventoryRepositoryFailure.forbidden:
        return 'Bu stok kartına erişim yetkiniz bulunmuyor.';
      case InventoryRepositoryFailure.noActiveTenant:
        return 'Stok detayı için aktif klinik oturumu gerekli.';
      case InventoryRepositoryFailure.notConfigured:
        return 'Stok detayı şu anda görüntülenemiyor.';
      case InventoryRepositoryFailure.network:
        return 'Stok detayı yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case InventoryRepositoryFailure.notFound:
        return notFoundDescription;
      case InventoryRepositoryFailure.invalidRow:
      case InventoryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
