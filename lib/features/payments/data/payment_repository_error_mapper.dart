import 'payment_repository_failure.dart';

/// PostgREST / Supabase hatalarını güvenli [PaymentRepositoryException]'a çevirir.
abstract final class PaymentRepositoryErrorMapper {
  static PaymentRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const PaymentRepositoryException(
        PaymentRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const PaymentRepositoryException(
        PaymentRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const PaymentRepositoryException(
        PaymentRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const PaymentRepositoryException(
        PaymentRepositoryFailure.notConfigured,
      );
    }
    return const PaymentRepositoryException(PaymentRepositoryFailure.unknown);
  }
}
