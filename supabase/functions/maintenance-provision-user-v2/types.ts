export interface ProvisionRequest {
  email: string;
  display_name: string;
  login_username?: string;
  tenant_id: string;
  role: "doctor_admin";
  membership_status: "active";
  mode: "create";
}

export type ProvisionErrorCode =
  | "unauthorized"
  | "operator_required"
  | "maintenance_disabled"
  | "invalid_email"
  | "invalid_role"
  | "invalid_status"
  | "invalid_arguments"
  | "invalid_mode"
  | "tenant_not_found"
  | "tenant_inactive"
  | "auth_user_exists"
  | "profile_conflict"
  | "membership_exists"
  | "bootstrap_partial_failure"
  | "auth_create_failed"
  | "database_bootstrap_failed"
  | "rollback_failed"
  | "unknown";

export interface ProvisionSuccessResponse {
  ok: true;
  operation_result: "created" | "already_exists";
  auth_user_id: string;
  profile_id?: string | null;
  membership_id?: string | null;
  login_username?: string;
}

export interface ProvisionErrorResponse {
  ok: false;
  error: ProvisionErrorCode | string;
}

export type ProvisionResponse = ProvisionSuccessResponse | ProvisionErrorResponse;
