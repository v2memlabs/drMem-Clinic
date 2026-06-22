import '../data/backend_config.dart';
import 'membership_loader.dart';
import 'mock_membership_loader.dart';
import 'supabase_membership_loader.dart';

/// Backend moduna göre membership loader.
abstract final class MembershipResolver {
  static MembershipLoader get loader => _resolve();

  static MembershipLoader _resolve() {
    if (AppBackendConfig.isMock) {
      return const MockMembershipLoader();
    }
    return const SupabaseMembershipLoader();
  }
}
