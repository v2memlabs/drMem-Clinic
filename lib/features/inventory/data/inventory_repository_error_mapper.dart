import 'inventory_repository_failure.dart';

/// PostgREST / Supabase / RPC hatalarını güvenli exception veya validation mesajına çevirir.
abstract final class InventoryRepositoryErrorMapper {
  static const _validationCodes = <String, String>{
    'INV_MOV_ITEM_NOT_FOUND': 'Stok kartı bulunamadı.',
    'INV_MOV_ITEM_INACTIVE': 'Pasif stok kartına hareket eklenemez.',
    'INV_MOV_INVALID_QTY': 'Miktar sıfırdan büyük olmalıdır.',
    'INV_MOV_INSUFFICIENT_STOCK': 'Çıkış miktarı mevcut stoktan fazla olamaz.',
    'INV_MOV_NEGATIVE_RESULT': 'Stok miktarı negatif olamaz.',
    'INV_MOV_PATIENT_TENANT': 'Hasta kaydı bu klinik kapsamında bulunamadı.',
    'INV_MOV_INVALID_TYPE': 'Geçersiz hareket türü.',
  };

  static InventoryRepositoryException toException(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (message.contains('INV_MOV_FORBIDDEN') ||
        lower.contains('jwt') ||
        lower.contains('permission') ||
        lower.contains('forbidden') ||
        lower.contains('42501')) {
      return const InventoryRepositoryException(
        InventoryRepositoryFailure.forbidden,
      );
    }
    if (lower.contains('not found') || lower.contains('pgrst116')) {
      return const InventoryRepositoryException(
        InventoryRepositoryFailure.notFound,
      );
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return const InventoryRepositoryException(
        InventoryRepositoryFailure.network,
      );
    }
    if (lower.contains('not configured') ||
        lower.contains('supabase') && lower.contains('init')) {
      return const InventoryRepositoryException(
        InventoryRepositoryFailure.notConfigured,
      );
    }
    return const InventoryRepositoryException(InventoryRepositoryFailure.unknown);
  }

  /// RPC stok validation — mock parity Türkçe mesaj; teknik metin UI'a gitmez.
  static String? toValidationMessage(Object error) {
    final message = error.toString();
    for (final entry in _validationCodes.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
