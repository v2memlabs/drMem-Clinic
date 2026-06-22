import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { ProvisionRequest, ProvisionResponse } from "./types.ts";
import { mapAuthError, mapRpcError, provisionEnvError } from "./error_mapper.ts";
import { buildCorsHeaders } from "../_shared/cors.ts";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function normalizeLoginUsername(raw: string): string {
  return raw.trim().toLowerCase().replace(/[^a-z0-9._]/g, "");
}

function isValidLoginUsername(raw: string): boolean {
  const normalized = normalizeLoginUsername(raw);
  return normalized.length >= 3 && normalized.length <= 32;
}

async function sendCredentialsEmail(
  supabaseUrl: string,
  serviceRoleKey: string,
  payload: {
    email: string;
    login_username: string;
    display_name: string;
    template: "credentials_ready";
    password: string;
  },
): Promise<void> {
  try {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/send-account-credentials-email`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      },
    );
    if (!response.ok) {
      console.error("credentials email invoke failed", response.status);
    }
  } catch (error) {
    console.error("credentials email invoke error", redactForLog(error));
  }
}

function generateTemporaryPassword(length = 20): string {
  const alphabet =
    "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*";
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += alphabet[bytes[i] % alphabet.length];
  }
  return out;
}

function redactForLog(value: unknown): unknown {
  if (value == null) return value;
  if (typeof value === "string") {
    if (value.length >= 12) return "[REDACTED]";
    return value;
  }
  if (Array.isArray(value)) return value.map(redactForLog);
  if (typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const next: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(obj)) {
      const key = k.toLowerCase();
      if (
        key.includes("password") ||
        key.includes("token") ||
        key.includes("jwt") ||
        key.includes("secret") ||
        key.includes("service_role")
      ) {
        next[k] = "[REDACTED]";
      } else {
        next[k] = redactForLog(v);
      }
    }
    return next;
  }
  return value;
}

function jsonResponse(
  req: Request,
  body: ProvisionResponse,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...buildCorsHeaders(req), "Content-Type": "application/json" },
  });
}

async function assertMaintenanceOperator(
  userClient: SupabaseClient,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const { data, error } = await userClient.rpc("maintenance_ping");
  if (error) {
    const mapped = mapRpcError(error.message);
    return { ok: false, error: mapped };
  }
  if (!data || data.ok !== true) {
    return { ok: false, error: "operator_required" };
  }
  return { ok: true };
}

function validateRequest(body: ProvisionRequest): string | null {
  if (!body.email || !EMAIL_RE.test(body.email.trim())) {
    return "invalid_email";
  }
  if (!body.display_name || body.display_name.trim().length === 0) {
    return "invalid_arguments";
  }
  if (!body.tenant_id) return "invalid_arguments";
  if (body.role !== "doctor_admin") return "invalid_role";
  if (body.membership_status !== "active") return "invalid_status";
  if (body.mode !== "create") return "invalid_mode";
  if (!body.login_username || !isValidLoginUsername(body.login_username)) {
    return "invalid_arguments";
  }
  return null;
}

async function findAuthUserIdByEmail(
  adminClient: SupabaseClient,
  email: string,
): Promise<string | null> {
  const normalized = email.trim().toLowerCase();
  const { data, error } = await adminClient.auth.admin.listUsers({
    page: 1,
    perPage: 200,
  });
  if (error) {
    console.error("auth listUsers failed", error.message);
    return null;
  }
  const match = data.users.find(
    (u) => (u.email ?? "").toLowerCase() === normalized,
  );
  return match?.id ?? null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: buildCorsHeaders(req) });
  }

  const envError = provisionEnvError();
  if (envError) {
    return jsonResponse(req,{ ok: false, error: envError }, 403);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse(req,{ ok: false, error: "unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("missing supabase function secrets");
    return jsonResponse(req,{ ok: false, error: "maintenance_disabled" }, 503);
  }

  let body: ProvisionRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req,{ ok: false, error: "invalid_arguments" }, 400);
  }

  const validationError = validateRequest(body);
  if (validationError) {
    return jsonResponse(req,{ ok: false, error: validationError }, 400);
  }

  const userClient = createClient(supabaseUrl, anonKey || serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const operatorCheck = await assertMaintenanceOperator(userClient);
  if (!operatorCheck.ok) {
    return jsonResponse(req,{ ok: false, error: operatorCheck.error }, 403);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const email = body.email.trim();
  const tenantId = body.tenant_id;
  const displayName = body.display_name.trim();
  const loginUsername = normalizeLoginUsername(body.login_username!);

  const existingAuthId = await findAuthUserIdByEmail(adminClient, email);
  if (existingAuthId) {
    const { data: statusData, error: statusError } = await userClient.rpc(
      "maintenance_bootstrap_status_v2",
      {
        p_tenant_id: tenantId,
        p_auth_user_id: existingAuthId,
      },
    );
    if (statusError) {
      return jsonResponse(req,{ ok: false, error: mapRpcError(statusError.message) }, 409);
    }
    if (statusData?.chain_ok === true) {
      return jsonResponse(req,{
        ok: true,
        operation_result: "already_exists",
        auth_user_id: existingAuthId,
        profile_id: statusData.profile_id,
        membership_id: null,
      });
    }
    return jsonResponse(req,{ ok: false, error: "auth_user_exists" }, 409);
  }

  const temporaryPassword = generateTemporaryPassword(20);

  const { data: createdUser, error: createError } = await adminClient.auth.admin
    .createUser({
      email,
      password: temporaryPassword,
      email_confirm: true,
      user_metadata: { display_name: displayName },
    });

  if (createError || !createdUser.user) {
    console.error(
      "auth createUser failed",
      redactForLog(createError?.message ?? "unknown"),
    );
    return jsonResponse(req,{
      ok: false,
      error: mapAuthError(createError?.message),
    }, 502);
  }

  const createdUserId = createdUser.user.id;

  const { data: bootstrapData, error: bootstrapError } = await userClient.rpc(
    "maintenance_bootstrap_user_v2",
    {
      p_auth_user_id: createdUserId,
      p_email: email,
      p_display_name: displayName,
      p_tenant_id: tenantId,
      p_role: "doctor_admin",
      p_membership_status: "active",
      p_mode: "create",
    },
  );

  if (bootstrapError || bootstrapData?.ok !== true) {
    console.error(
      "bootstrap RPC failed",
      redactForLog(bootstrapError?.message ?? bootstrapData),
    );

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      createdUserId,
    );

    if (deleteError) {
      console.error("rollback deleteUser failed", deleteError.message);
      await userClient.rpc("maintenance_write_audit", {
        p_action: "maintenance.bootstrap.rollback_failed",
        p_record_id: createdUserId,
        p_target_tenant_id: tenantId,
        p_metadata: {
          target_tenant_id: tenantId,
          operation_result: "rollback_failed",
          source: "maintenance_v2a2",
        },
      }).catch(() => undefined);

      return jsonResponse(req,{ ok: false, error: "rollback_failed" }, 500);
    }

    await userClient.rpc("maintenance_write_audit", {
      p_action: "maintenance.bootstrap.partial_failure",
      p_record_id: createdUserId,
      p_target_tenant_id: tenantId,
      p_metadata: {
        target_tenant_id: tenantId,
        operation_result: "partial_failure",
        source: "maintenance_v2a2",
      },
    }).catch(() => undefined);

    return jsonResponse(req,{
      ok: false,
      error: mapRpcError(bootstrapError?.message) ?? "database_bootstrap_failed",
    }, 502);
  }

  const profileId = bootstrapData.profile_id as string;
  const { data: usernameData, error: usernameError } = await userClient.rpc(
    "set_profile_login_username_v1",
    {
      p_profile_id: profileId,
      p_login_username: loginUsername,
    },
  );

  if (usernameError || usernameData?.ok !== true) {
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      createdUserId,
    );

    if (deleteError) {
      console.error("rollback deleteUser failed", deleteError.message);
      return jsonResponse(req,{ ok: false, error: "rollback_failed" }, 500);
    }

    return jsonResponse(req,{
      ok: false,
      error: mapRpcError(usernameError?.message) ?? "database_bootstrap_failed",
    }, 409);
  }

  const resolvedUsername =
    (usernameData.login_username as string) ?? loginUsername;

  await sendCredentialsEmail(supabaseUrl, serviceRoleKey, {
    email,
    login_username: resolvedUsername,
    display_name: displayName,
    template: "credentials_ready",
    password: temporaryPassword,
  });

  console.log(
    "maintenance provision success",
    redactForLog({
      tenant_id: tenantId,
      profile_id: bootstrapData.profile_id,
      operation_result: bootstrapData.operation_result,
    }),
  );

  return jsonResponse(req,{
    ok: true,
    operation_result: bootstrapData.operation_result ?? "created",
    auth_user_id: createdUserId,
    profile_id: bootstrapData.profile_id,
    membership_id: bootstrapData.membership_id,
    login_username: resolvedUsername,
  });
});
