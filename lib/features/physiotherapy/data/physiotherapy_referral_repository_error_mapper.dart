import 'physiotherapy_referral_repository_failure.dart';

abstract final class PhysiotherapyReferralRepositoryErrorMapper {
  static PhysiotherapyReferralRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.notConfigured,
      );
    }
    return const PhysiotherapyReferralRepositoryException(
      PhysiotherapyReferralRepositoryFailure.unknown,
    );
  }
}
