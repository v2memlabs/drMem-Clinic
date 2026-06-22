import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { buildCorsHeaders } from "../_shared/cors.ts";

interface CredentialsEmailRequest {
  email?: string;
  login_username?: string;
  display_name?: string;
  password?: string;
  template?: "invite" | "credentials_ready";
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

function buildSubject(template: string, displayName: string): string {
  if (template === "credentials_ready") {
    return "Hesabınız hazır — giriş bilgileriniz";
  }
  return `${displayName} — klinik davetiniz ve giriş kullanıcı adınız`;
}

function buildHtmlBody(req: CredentialsEmailRequest): string {
  const name = (req.display_name ?? "").trim() || "Kullanıcı";
  const username = (req.login_username ?? "").trim();
  const template = req.template ?? "invite";

  if (template === "credentials_ready") {
    const password = req.password ?? "";
    return `
      <p>Merhaba ${name},</p>
      <p>Klinik hesabınız için şifreniz belirlendi. Giriş bilgileriniz:</p>
      <ul>
        <li><strong>Kullanıcı adı:</strong> ${username}</li>
        <li><strong>Şifre:</strong> ${password}</li>
      </ul>
      <p>Uygulamaya kullanıcı adınız ve şifreniz ile giriş yapabilirsiniz.</p>
      <p>Güvenliğiniz için bu e-postayı saklayın ve şifrenizi kimseyle paylaşmayın.</p>
    `;
  }

  return `
    <p>Merhaba ${name},</p>
    <p>Klinik hesabınıza davet edildiniz.</p>
    <p><strong>Giriş kullanıcı adınız:</strong> ${username}</p>
    <p>E-postanızdaki davet bağlantısı ile şifrenizi belirledikten sonra bu kullanıcı adı ile giriş yapacaksınız.</p>
  `;
}

async function sendViaResend(
  to: string,
  subject: string,
  html: string,
): Promise<boolean> {
  const apiKey = Deno.env.get("RESEND_API_KEY") ?? "";
  const from = Deno.env.get("ACCOUNT_EMAIL_FROM") ?? "";
  if (!apiKey || !from) {
    console.log("credentials email skipped — RESEND not configured");
    return false;
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      html,
    }),
  });

  if (!response.ok) {
    console.error("resend failed", response.status);
    return false;
  }
  return true;
}

function assertServiceRole(req: Request): boolean {
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!authHeader?.startsWith("Bearer ") || !serviceRoleKey) {
    return false;
  }
  return authHeader.slice(7) === serviceRoleKey;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: buildCorsHeaders(req) });
  }

  if (!assertServiceRole(req)) {
    return jsonResponse(req, { ok: false, error: "unauthorized" }, 401);
  }

  let body: CredentialsEmailRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, { ok: false, error: "invalid_arguments" }, 400);
  }

  const email = body.email?.trim() ?? "";
  const username = body.login_username?.trim() ?? "";
  const template = body.template ?? "invite";

  if (!email || !email.includes("@") || username.length < 3) {
    return jsonResponse(req, { ok: false, error: "invalid_arguments" }, 400);
  }

  if (template === "credentials_ready" && !(body.password?.trim())) {
    return jsonResponse(req, { ok: false, error: "invalid_arguments" }, 400);
  }

  const subject = buildSubject(template, body.display_name ?? "");
  const html = buildHtmlBody(body);
  const sent = await sendViaResend(email, subject, html);

  return jsonResponse(req, { ok: true, sent });
});
