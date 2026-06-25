export function mapRpcError(message?: string | null): string {
  const msg = (message ?? "").toLowerCase();
  if (msg.includes("forbidden") || msg.includes("no_active_profile")) {
    return "doctor_admin_required";
  }
  if (msg.includes("no_active_tenant")) return "no_active_tenant";
  if (msg.includes("tenant_inactive")) return "tenant_inactive";
  if (msg.includes("invalid_email")) return "invalid_email";
  if (msg.includes("invalid_display_name")) return "invalid_display_name";
  if (msg.includes("invalid_role")) return "invalid_role";
  if (msg.includes("invalid_login_username")) return "invalid_login_username";
  if (msg.includes("login_username_taken")) return "login_username_taken";
  if (msg.includes("self_invite_blocked")) return "self_invite_blocked";
  if (msg.includes("profile_conflict")) return "profile_conflict";
  if (msg.includes("auth_user_already_linked")) {
    return "auth_user_already_linked";
  }
  if (msg.includes("membership_already_active")) {
    return "membership_already_active";
  }
  if (msg.includes("invitation_already_pending")) {
    return "invitation_already_pending";
  }
  if (msg.includes("invitation_not_found")) return "invitation_not_found";
  if (msg.includes("invitation_not_pending")) return "invitation_not_pending";
  if (msg.includes("invite_rate_limited")) return "invite_rate_limited";
  if (msg.includes("maintenance_operator_target")) {
    return "profile_conflict";
  }
  if (msg.includes("auth_user_not_found")) return "auth_invite_failed";
  if (msg.includes("auth_user_exists")) return "auth_user_exists";
  return "database_bootstrap_failed";
}

export function mapPasswordValidation(raw?: string | null): string | null {
  const password = raw?.trim() ?? "";
  if (password.length < 8) return "invalid_password";
  return null;
}

export function mapAuthError(message?: string | null): string {
  const msg = (message ?? "").toLowerCase();
  if (msg.includes("already") && msg.includes("registered")) {
    return "auth_user_exists";
  }
  if (msg.includes("invalid") && msg.includes("email")) return "invalid_email";
  if (msg.includes("rate") && msg.includes("limit")) return "auth_email_rate_limited";
  if (msg.includes("over_email_send_rate_limit")) return "auth_email_rate_limited";
  return "auth_invite_failed";
}
