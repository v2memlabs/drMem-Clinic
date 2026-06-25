import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { buildCorsHeaders } from "../_shared/cors.ts";
import type { InviteRequest, InviteResponse, ResendContext } from "./types.ts";
import { mapAuthError, mapPasswordValidation, mapRpcError } from "./error_mapper.ts";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const VALID_ROLES = new Set([
  "doctor_admin",
  "assistant_secretary",
  "physiotherapist",
  "nurse",
]);
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const INVITE_ACCEPT_PATH = "/invite/accept";
const MEMBERSHIP_ID_PARAM = "membership_id";

function normalizeLoginUsername(raw: string): string {
  return raw.trim().toLowerCase().replace(/[^a-z0-9._]/g, "");
}

function isValidLoginUsername(raw: string): boolean {
  const normalized = normalizeLoginUsername(raw);
  return normalized.length >= 3 && normalized.length <= 32;
}

async function sendCredentialsInviteEmail(
  supabaseUrl: string,
  serviceRoleKey: string,
  payload: {
    email: string;
    login_username: string;
    display_name: string;
    template: "invite" | "credentials_ready";
    password?: string;
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

async function setProfileLoginUsername(
  userClient: SupabaseClient,
  profileId: string,
  loginUsername: string,
): Promise<{ ok: true; login_username: string } | { ok: false; error: string }> {
  const { data, error } = await userClient.rpc("set_profile_login_username_v1", {
    p_profile_id: profileId,
    p_login_username: loginUsername,
  });
  if (error || data?.ok !== true) {
    return { ok: false, error: mapRpcError(error?.message) };
  }
  return {
    ok: true,
    login_username: (data.login_username as string) ?? loginUsername,
  };
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
        key.includes("service_role") ||
        key.includes("email") ||
        key.includes("redirect")
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
  body: InviteResponse,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...buildCorsHeaders(req), "Content-Type": "application/json" },
  });
}

function resolveRedirectUrl(requested?: string): string | undefined {
  const allowlistRaw = Deno.env.get("TENANT_INVITE_REDIRECT_URLS") ??
    Deno.env.get("SUPABASE_SITE_URL") ?? "";
  const allowed = allowlistRaw
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  if (allowed.length === 0) return undefined;

  const candidate = requested?.trim();
  if (!candidate) return allowed[0];

  if (allowed.includes(candidate)) return candidate;
  return undefined;
}

function buildInviteAcceptRedirect(
  membershipId: string,
  requested?: string,
): string | undefined {
  if (!UUID_RE.test(membershipId)) return undefined;
  const base = resolveRedirectUrl(requested);
  if (!base) return undefined;

  try {
    const url = new URL(base);
    url.pathname = INVITE_ACCEPT_PATH;
    url.search = "";
    url.searchParams.set(MEMBERSHIP_ID_PARAM, membershipId.toLowerCase());
    return url.toString();
  } catch {
    const trimmed = base.replace(/\/$/, "");
    const pathBase = trimmed.includes(INVITE_ACCEPT_PATH)
      ? trimmed.split("?")[0]
      : `${trimmed}${INVITE_ACCEPT_PATH}`;
    return `${pathBase}?${MEMBERSHIP_ID_PARAM}=${membershipId.toLowerCase()}`;
  }
}

function validateInviteRequest(body: InviteRequest): string | null {
  if (!body.email || !EMAIL_RE.test(body.email.trim())) {
    return "invalid_email";
  }
  if (!body.display_name || body.display_name.trim().length === 0) {
    return "invalid_display_name";
  }
  if (!body.role || !VALID_ROLES.has(body.role)) return "invalid_role";
  if (!body.login_username || !isValidLoginUsername(body.login_username)) {
    return "invalid_login_username";
  }
  if (body.redirect_url && !resolveRedirectUrl(body.redirect_url)) {
    return "invalid_arguments";
  }
  return null;
}

function validateResendRequest(body: InviteRequest): string | null {
  if (!body.membership_id || !UUID_RE.test(body.membership_id.trim())) {
    return "invalid_arguments";
  }
  if (body.redirect_url && !resolveRedirectUrl(body.redirect_url)) {
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

async function assertDoctorAdmin(
  userClient: SupabaseClient,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const { error } = await userClient.rpc("list_tenant_memberships_v1");
  if (error) {
    const mapped = mapRpcError(error.message);
    if (mapped === "doctor_admin_required" || mapped === "no_active_tenant") {
      return { ok: false, error: mapped };
    }
    return { ok: false, error: "doctor_admin_required" };
  }
  return { ok: true };
}

async function sendInviteEmail(
  adminClient: SupabaseClient,
  email: string,
  displayName: string,
  redirectTo?: string,
  existingUserId?: string | null,
): Promise<{ ok: true; userId: string; created: boolean } | { ok: false; error: string }> {
  if (existingUserId) {
    const linkOptions: {
      type: "invite";
      email: string;
      options?: { redirectTo: string };
    } = {
      type: "invite",
      email: email.trim(),
    };
    if (redirectTo) {
      linkOptions.options = { redirectTo };
    }

    const { error: linkError } = await adminClient.auth.admin.generateLink(
      linkOptions,
    );
    if (linkError) {
      console.error("generateLink failed", redactForLog(linkError.message));
      return { ok: false, error: mapAuthError(linkError.message) };
    }
    return { ok: true, userId: existingUserId, created: false };
  }

  const { data, error } = await adminClient.auth.admin.inviteUserByEmail(
    email.trim(),
    {
      data: { display_name: displayName.trim() },
      redirectTo,
    },
  );

  if (error || !data.user) {
    console.error("inviteUserByEmail failed", redactForLog(error?.message));
    return { ok: false, error: mapAuthError(error?.message) };
  }

  return { ok: true, userId: data.user.id, created: true };
}

async function handleInviteMode(
  req: Request,
  userClient: SupabaseClient,
  adminClient: SupabaseClient,
  body: InviteRequest,
  supabaseUrl: string,
  serviceRoleKey: string,
): Promise<Response> {
  const validationError = validateInviteRequest(body);
  if (validationError) {
    return jsonResponse(req,{ ok: false, error: validationError }, 400);
  }

  const email = body.email!.trim();
  const displayName = body.display_name!.trim();
  const loginUsername = normalizeLoginUsername(body.login_username!);
  const role = body.role!;
  const targetMembershipId = crypto.randomUUID();

  const redirectTo = buildInviteAcceptRedirect(
    targetMembershipId,
    body.redirect_url,
  );

  const existingAuthId = await findAuthUserIdByEmail(adminClient, email);

  const inviteResult = await sendInviteEmail(
    adminClient,
    email,
    displayName,
    redirectTo,
    existingAuthId,
  );

  if (!inviteResult.ok) {
    return jsonResponse(req,{ ok: false, error: inviteResult.error }, 502);
  }

  const authUserId = inviteResult.userId;
  const authCreated = inviteResult.created;

  const { data: bootstrapData, error: bootstrapError } = await userClient.rpc(
    "bootstrap_tenant_invited_user_v2",
    {
      p_auth_user_id: authUserId,
      p_email: email,
      p_display_name: displayName,
      p_role: role,
      p_target_membership_id: targetMembershipId,
    },
  );

  if (bootstrapError || bootstrapData?.ok !== true) {
    console.error(
      "bootstrap RPC failed",
      redactForLog(bootstrapError?.message ?? bootstrapData),
    );

    if (authCreated) {
      const { error: deleteError } = await adminClient.auth.admin.deleteUser(
        authUserId,
      );
      if (deleteError) {
        console.error("rollback deleteUser failed", deleteError.message);
        return jsonResponse(req,{ ok: false, error: "rollback_failed" }, 500);
      }
    }

    const mapped = mapRpcError(bootstrapError?.message);
    return jsonResponse(req,{ ok: false, error: mapped }, 502);
  }

  const profileId = bootstrapData.target_profile_id as string;
  const usernameResult = await setProfileLoginUsername(
    userClient,
    profileId,
    loginUsername,
  );

  if (!usernameResult.ok) {
    if (authCreated) {
      const { error: deleteError } = await adminClient.auth.admin.deleteUser(
        authUserId,
      );
      if (deleteError) {
        console.error("rollback deleteUser failed", deleteError.message);
        return jsonResponse(req,{ ok: false, error: "rollback_failed" }, 500);
      }
    }
    return jsonResponse(req,{ ok: false, error: usernameResult.error }, 409);
  }

  await sendCredentialsInviteEmail(supabaseUrl, serviceRoleKey, {
    email,
    login_username: usernameResult.login_username,
    display_name: displayName,
    template: "invite",
  });

  console.log(
    "tenant invite success",
    redactForLog({
      operation_result: bootstrapData.operation_result,
      target_profile_id: bootstrapData.target_profile_id,
      target_membership_id: bootstrapData.target_membership_id,
    }),
  );

  return jsonResponse(req,{
    ok: true,
    operation_result: bootstrapData.operation_result ?? "created",
    target_profile_id: bootstrapData.target_profile_id,
    target_membership_id: bootstrapData.target_membership_id,
    role: bootstrapData.role,
    status: bootstrapData.status,
  });
}

function validateProvisionRequest(body: InviteRequest): string | null {
  const base = validateInviteRequest(body);
  if (base) return base;
  return mapPasswordValidation(body.password);
}

async function handleProvisionMode(
  req: Request,
  userClient: SupabaseClient,
  adminClient: SupabaseClient,
  body: InviteRequest,
): Promise<Response> {
  const validationError = validateProvisionRequest(body);
  if (validationError) {
    return jsonResponse(req, { ok: false, error: validationError }, 400);
  }

  const email = body.email!.trim();
  const displayName = body.display_name!.trim();
  const loginUsername = normalizeLoginUsername(body.login_username!);
  const role = body.role!;
  const password = body.password!.trim();
  const targetMembershipId = crypto.randomUUID();

  const existingAuthId = await findAuthUserIdByEmail(adminClient, email);
  if (existingAuthId) {
    return jsonResponse(req, { ok: false, error: "auth_user_exists" }, 409);
  }

  const { data: createdUser, error: createError } = await adminClient.auth.admin
    .createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        display_name: displayName,
        must_change_password: true,
      },
    });

  if (createError || !createdUser.user) {
    console.error(
      "auth createUser failed",
      redactForLog(createError?.message ?? "unknown"),
    );
    return jsonResponse(req, { ok: false, error: mapAuthError(createError?.message) }, 502);
  }

  const authUserId = createdUser.user.id;

  const { data: bootstrapData, error: bootstrapError } = await userClient.rpc(
    "bootstrap_tenant_provisioned_user_v2",
    {
      p_auth_user_id: authUserId,
      p_email: email,
      p_display_name: displayName,
      p_role: role,
      p_target_membership_id: targetMembershipId,
    },
  );

  if (bootstrapError || bootstrapData?.ok !== true) {
    console.error(
      "provision bootstrap RPC failed",
      redactForLog(bootstrapError?.message ?? bootstrapData),
    );

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      authUserId,
    );
    if (deleteError) {
      console.error("rollback deleteUser failed", deleteError.message);
      return jsonResponse(req, { ok: false, error: "rollback_failed" }, 500);
    }

    const mapped = mapRpcError(bootstrapError?.message);
    return jsonResponse(req, { ok: false, error: mapped }, 502);
  }

  const profileId = bootstrapData.target_profile_id as string;
  const usernameResult = await setProfileLoginUsername(
    userClient,
    profileId,
    loginUsername,
  );

  if (!usernameResult.ok) {
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      authUserId,
    );
    if (deleteError) {
      console.error("rollback deleteUser failed", deleteError.message);
      return jsonResponse(req, { ok: false, error: "rollback_failed" }, 500);
    }
    return jsonResponse(req, { ok: false, error: usernameResult.error }, 409);
  }

  console.log(
    "tenant provision success",
    redactForLog({
      operation_result: bootstrapData.operation_result,
      target_profile_id: bootstrapData.target_profile_id,
      target_membership_id: bootstrapData.target_membership_id,
    }),
  );

  return jsonResponse(req, {
    ok: true,
    operation_result: bootstrapData.operation_result ?? "created",
    target_profile_id: bootstrapData.target_profile_id,
    target_membership_id: bootstrapData.target_membership_id,
    role: bootstrapData.role,
    status: bootstrapData.status,
  });
}

async function handleResendMode(
  req: Request,
  userClient: SupabaseClient,
  adminClient: SupabaseClient,
  body: InviteRequest,
  supabaseUrl: string,
  serviceRoleKey: string,
): Promise<Response> {
  const validationError = validateResendRequest(body);
  if (validationError) {
    return jsonResponse(req,{ ok: false, error: validationError }, 400);
  }

  const membershipId = body.membership_id!.trim();
  const redirectTo = buildInviteAcceptRedirect(membershipId, body.redirect_url);

  const { data: prepareData, error: prepareError } = await userClient.rpc(
    "prepare_tenant_invitation_resend_v2",
    { p_membership_id: membershipId },
  );

  if (prepareError || prepareData?.ok !== true) {
    console.error(
      "prepare resend failed",
      redactForLog(prepareError?.message ?? prepareData),
    );
    return jsonResponse(req,
      { ok: false, error: mapRpcError(prepareError?.message) },
      prepareError?.message?.includes("invite_rate_limited") ? 429 : 409,
    );
  }

  const ctx = prepareData as ResendContext;
  const inviteResult = await sendInviteEmail(
    adminClient,
    ctx.email,
    ctx.display_name,
    redirectTo,
    ctx.auth_user_id,
  );

  if (!inviteResult.ok) {
    return jsonResponse(req,{ ok: false, error: inviteResult.error }, 502);
  }

  const { data: profileRow } = await adminClient
    .from("profiles")
    .select("login_username")
    .eq("id", ctx.target_profile_id)
    .maybeSingle();

  const loginUsername = (profileRow?.login_username as string | null)?.trim();
  if (loginUsername && isValidLoginUsername(loginUsername)) {
    await sendCredentialsInviteEmail(supabaseUrl, serviceRoleKey, {
      email: ctx.email,
      login_username: normalizeLoginUsername(loginUsername),
      display_name: ctx.display_name,
      template: "invite",
    });
  }

  const { data: completeData, error: completeError } = await userClient.rpc(
    "complete_tenant_invitation_resend_v2",
    { p_membership_id: membershipId },
  );

  if (completeError || completeData?.ok !== true) {
    console.error(
      "complete resend failed",
      redactForLog(completeError?.message ?? completeData),
    );
    return jsonResponse(req,
      { ok: false, error: mapRpcError(completeError?.message) },
      502,
    );
  }

  console.log(
    "tenant invite resend success",
    redactForLog({
      target_membership_id: completeData.target_membership_id,
      operation_result: completeData.operation_result,
    }),
  );

  return jsonResponse(req,{
    ok: true,
    operation_result: completeData.operation_result ?? "resent",
    target_profile_id: completeData.target_profile_id,
    target_membership_id: completeData.target_membership_id,
    role: completeData.role,
    status: completeData.status,
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: buildCorsHeaders(req) });
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
    return jsonResponse(req,{ ok: false, error: "unknown" }, 503);
  }

  let body: InviteRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req,{ ok: false, error: "invalid_arguments" }, 400);
  }

  const userClient = createClient(supabaseUrl, anonKey || serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const adminCheck = await assertDoctorAdmin(userClient);
  if (!adminCheck.ok) {
    return jsonResponse(req,{ ok: false, error: adminCheck.error }, 403);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const mode = body.mode ?? "provision";
  if (mode === "resend") {
    return handleResendMode(req, userClient, adminClient, body, supabaseUrl, serviceRoleKey);
  }
  if (mode === "provision") {
    return handleProvisionMode(req, userClient, adminClient, body);
  }
  if (mode === "invite") {
    return handleInviteMode(req, userClient, adminClient, body, supabaseUrl, serviceRoleKey);
  }

  return jsonResponse(req, { ok: false, error: "invalid_arguments" }, 400);
});
