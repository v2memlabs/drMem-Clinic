/// Plan ve abonelik durumu — kullanıcıya gösterilen etiketler.
abstract final class SaasPlanLabels {
  static String planLabel(String? planKey) {
    switch (planKey?.trim()) {
      case 'starter':
        return 'Başlangıç';
      case 'pro':
        return 'Profesyonel';
      case 'demo':
        return 'Demo';
      default:
        return 'Standart';
    }
  }

  static String statusLabel(String? status) {
    switch (status?.trim()) {
      case 'trialing':
        return 'Deneme';
      case 'past_due':
        return 'Ödeme gecikmiş';
      case 'canceled':
        return 'İptal';
      case 'active':
      default:
        return 'Aktif';
    }
  }

  static int? defaultSeatLimitForPlan(String planKey) {
    switch (planKey.trim()) {
      case 'demo':
        return 5;
      case 'starter':
        return 10;
      case 'pro':
        return 25;
      default:
        return null;
    }
  }
}
