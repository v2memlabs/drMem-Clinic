  /// Aktif tenant üyesi — ayarlar ekranı listesi (teknik id UI'da gösterilmez).
class TenantMembershipUser {
  final String membershipId;
  final String profileId;
  final String displayName;
  final String? email;
  final String? loginUsername;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TenantMembershipUser({
    required this.membershipId,
    this.profileId = '',
    required this.displayName,
    this.email,
    this.loginUsername,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory TenantMembershipUser.fromListRow(Map<String, dynamic> json) {
    return TenantMembershipUser(
      membershipId: json['membership_id'] as String,
      profileId: (json['profile_id'] as String?)?.trim() ?? '',
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? (json['display_name'] as String).trim()
          : 'Kullanıcı',
      email: (json['email'] as String?)?.trim(),
      loginUsername: (json['login_username'] as String?)?.trim(),
      role: json['role'] as String? ?? 'assistant_secretary',
      status: json['status'] as String? ?? 'active',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static List<TenantMembershipUser> parseListResponse(Object? data) {
    if (data == null) return const [];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TenantMembershipUser.fromListRow)
        .toList(growable: false);
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  bool get isActiveDoctorAdmin =>
      role == 'doctor_admin' && status == 'active';

  bool get isActivePhysiotherapist =>
      role == 'physiotherapist' && status == 'active';
}
