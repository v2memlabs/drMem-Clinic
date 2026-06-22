import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'tenant_invite_error_mapper.dart';
import 'tenant_invite_failure.dart';
import 'tenant_invite_models.dart';
import 'tenant_invite_repository.dart';

class SupabaseTenantInviteRepository implements TenantInviteRepository {
  SupabaseTenantInviteRepository(this._client);

  factory SupabaseTenantInviteRepository.fromSupabase() {
    return SupabaseTenantInviteRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.notConfigured,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.notConfigured),
      );
    }
  }

  void _ensureCanManageInvites() {
    if (!AuthSession.canEditClinicProfile) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.forbidden,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.forbidden),
      );
    }
    if (ActiveTenantContextStore.current == null || !SessionReadiness.isReady) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.noActiveTenant,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.noActiveTenant),
      );
    }
  }

  TenantInviteRepositoryException _mapFunctionResponse(
    Map<String, dynamic> payload,
  ) {
    final failure = TenantInviteErrorMapper.fromFunctionError(
      payload['error'] as String?,
    );
    return TenantInviteRepositoryException(
      failure,
      TenantInviteErrorMapper.messageFor(failure),
    );
  }

  TenantInviteRepositoryException _mapFunctionException(FunctionException e) {
    final code = _extractFunctionErrorCode(e);
    if (code != null) {
      final failure = TenantInviteErrorMapper.fromFunctionError(code);
      return TenantInviteRepositoryException(
        failure,
        TenantInviteErrorMapper.messageFor(failure),
      );
    }
    return TenantInviteRepositoryException(
      TenantInviteFailure.unknown,
      TenantInviteErrorMapper.messageFor(TenantInviteFailure.unknown),
    );
  }

  String? _extractFunctionErrorCode(FunctionException e) {
    final details = e.details;
    if (details is Map<String, dynamic>) {
      final error = details['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    if (details is Map) {
      final error = details['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    if (details is String && details.isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          final error = decoded['error'];
          if (error is String && error.isNotEmpty) return error;
        }
      } catch (_) {}
    }
    final phrase = e.reasonPhrase?.trim();
    if (phrase != null && phrase.isNotEmpty && !phrase.contains(' ')) {
      return phrase;
    }
    return null;
  }

  Future<Map<String, dynamic>> _invokeFunction(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(
      'tenant-invite-user-v2',
      body: body,
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invalidResponse,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.invalidResponse),
      );
    }

    if (payload['ok'] != true) {
      throw _mapFunctionResponse(payload);
    }

    return payload;
  }

  @override
  Future<TenantInviteResult> inviteUser(TenantInviteRequest request) async {
    _ensureConfigured();
    _ensureCanManageInvites();

    try {
      final payload = await _invokeFunction({
        'mode': 'invite',
        'email': request.email.trim(),
        'display_name': request.displayName.trim(),
        'login_username': request.loginUsername.trim(),
        'role': request.role,
      });
      return TenantInviteResult.fromJson(payload);
    } on TenantInviteRepositoryException {
      rethrow;
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } catch (e) {
      if (e is TenantInviteRepositoryException) rethrow;
      throw TenantInviteRepositoryException(
        TenantInviteFailure.unknown,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.unknown),
      );
    }
  }

  @override
  Future<TenantInviteResult> resendInvitation(String membershipId) async {
    _ensureConfigured();
    _ensureCanManageInvites();

    try {
      final payload = await _invokeFunction({
        'mode': 'resend',
        'membership_id': membershipId,
      });
      return TenantInviteResult.fromJson(payload);
    } on TenantInviteRepositoryException {
      rethrow;
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } catch (e) {
      if (e is TenantInviteRepositoryException) rethrow;
      throw TenantInviteRepositoryException(
        TenantInviteFailure.unknown,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.unknown),
      );
    }
  }

  @override
  Future<InvitationCancelResult> cancelInvitation(String membershipId) async {
    _ensureConfigured();
    _ensureCanManageInvites();

    try {
      final data = await _client.rpc(
        'cancel_tenant_invitation_v2',
        params: {'p_membership_id': membershipId},
      );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw TenantInviteRepositoryException(
          TenantInviteFailure.unknown,
          TenantInviteErrorMapper.messageFor(TenantInviteFailure.unknown),
        );
      }
      return InvitationCancelResult.fromJson(data);
    } on PostgrestException catch (e) {
      final failure = TenantInviteErrorMapper.fromPostgrest(e);
      throw TenantInviteRepositoryException(
        failure,
        TenantInviteErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantInviteRepositoryException) rethrow;
      throw TenantInviteRepositoryException(
        TenantInviteFailure.unknown,
        TenantInviteErrorMapper.messageFor(TenantInviteFailure.unknown),
      );
    }
  }

  @override
  Future<InvitationAcceptResult> acceptMyInvitation({
    String? membershipId,
  }) async {
    _ensureConfigured();

    final params = <String, dynamic>{};
    if (membershipId != null && membershipId.isNotEmpty) {
      params['p_membership_id'] = membershipId;
    }

    try {
      final data = params.isEmpty
          ? await _client.rpc('accept_my_tenant_invitation_v2')
          : await _client.rpc(
              'accept_my_tenant_invitation_v2',
              params: params,
            );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw TenantInviteRepositoryException(
          TenantInviteFailure.invitationAcceptFailed,
          TenantInviteErrorMapper.messageFor(
            TenantInviteFailure.invitationAcceptFailed,
          ),
        );
      }
      return InvitationAcceptResult.fromJson(data);
    } on PostgrestException catch (e) {
      final failure = TenantInviteErrorMapper.fromPostgrestForAccept(e);
      throw TenantInviteRepositoryException(
        failure,
        TenantInviteErrorMapper.messageFor(failure),
      );
    } catch (e) {
      if (e is TenantInviteRepositoryException) rethrow;
      throw TenantInviteRepositoryException(
        TenantInviteFailure.invitationAcceptFailed,
        TenantInviteErrorMapper.messageFor(
          TenantInviteFailure.invitationAcceptFailed,
        ),
      );
    }
  }
}
