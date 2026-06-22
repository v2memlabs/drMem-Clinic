import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { buildCorsHeaders } from "../_shared/cors.ts";

interface SignInRequest {
  username?: string;
  password?: string;
}

function jsonResponse(
  req: Request,
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...buildCorsHeaders(req), "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: buildCorsHeaders(req) });
  }

  if (req.method !== "POST") {
    return jsonResponse(req, { ok: false, error: "invalid_arguments" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    console.error("sign-in-with-username missing secrets");
    return jsonResponse(req, { ok: false, error: "unavailable" }, 503);
  }

  let body: SignInRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, { ok: false, error: "invalid_credentials" }, 401);
  }

  const username = body.username?.trim() ?? "";
  const password = body.password ?? "";

  if (username.length < 3 || password.length === 0) {
    return jsonResponse(req, { ok: false, error: "invalid_credentials" }, 401);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: resolvedEmail, error: resolveError } = await adminClient.rpc(
    "resolve_login_email",
    { p_login_username: username },
  );

  const email = typeof resolvedEmail === "string" ? resolvedEmail.trim() : "";
  if (resolveError || !email) {
    return jsonResponse(req, { ok: false, error: "invalid_credentials" }, 401);
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: signInData, error: signInError } = await authClient.auth
    .signInWithPassword({ email, password });

  if (signInError || !signInData.session) {
    return jsonResponse(req, { ok: false, error: "invalid_credentials" }, 401);
  }

  const session = signInData.session;
  return jsonResponse(req, {
    ok: true,
    session: {
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      expires_at: session.expires_at,
      token_type: session.token_type,
      user: session.user,
    },
  });
});
