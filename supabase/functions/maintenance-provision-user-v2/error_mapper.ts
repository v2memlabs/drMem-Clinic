export function provisionEnvError(): string | null {
  const appEnv = (Deno.env.get("APP_ENV") ?? Deno.env.get("ENVIRONMENT") ?? "")
    .toLowerCase();
  if (appEnv === "production" || appEnv === "prod") {
    return "maintenance_disabled";
  }

  const enabled = (Deno.env.get("MAINTENANCE_PROVISIONING_ENABLED") ?? "")
    .toLowerCase();
  if (enabled !== "true" && enabled !== "1") {
    return "maintenance_disabled";
  }

  return null;
}

export function mapRpcError(message?: string | null): string {
  const msg = (message ?? "").toLowerCase();
  if (msg.includes("maintenance_disabled")) return "maintenance_disabled";
  if (msg.includes("maintenance_forbidden")) return "operator_required";
  if (msg.includes("invalid_email")) return "invalid_email";
  if (msg.includes("invalid_role")) return "invalid_role";
  if (msg.includes("invalid_status")) return "invalid_status";
  if (msg.includes("tenant_not_found")) return "tenant_not_found";
  if (msg.includes("tenant_inactive")) return "tenant_inactive";
  if (msg.includes("profile_conflict")) return "profile_conflict";
  if (msg.includes("auth_user_already_linked")) return "profile_conflict";
  if (msg.includes("membership_exists")) return "membership_exists";
  if (msg.includes("maintenance_operator_target")) {
    return "profile_conflict";
  }
  if (msg.includes("rollback_failed")) return "rollback_failed";
  return "database_bootstrap_failed";
}

export function mapAuthError(message?: string | null): string {
  const msg = (message ?? "").toLowerCase();
  if (msg.includes("already") && msg.includes("registered")) {
    return "auth_user_exists";
  }
  if (msg.includes("invalid") && msg.includes("email")) return "invalid_email";
  return "auth_create_failed";
}
