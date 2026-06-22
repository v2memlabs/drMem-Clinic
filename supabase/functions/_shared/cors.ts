const DEFAULT_CORS_ORIGINS = [
  "http://localhost:3000",
  "http://127.0.0.1:3000",
  "http://localhost:8080",
  "http://127.0.0.1:8080",
];

function parseAllowedOrigins(): string[] {
  const configured = Deno.env.get("ALLOWED_CORS_ORIGINS");
  if (!configured || configured.trim().length === 0) {
    return DEFAULT_CORS_ORIGINS;
  }
  return configured
    .split(",")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0);
}

export function buildCorsHeaders(req: Request): Record<string, string> {
  const allowed = parseAllowedOrigins();
  const origin = req.headers.get("Origin");
  const baseHeaders = {
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  if (!origin || !allowed.includes(origin)) {
    return baseHeaders;
  }

  return {
    ...baseHeaders,
    "Access-Control-Allow-Origin": origin,
    Vary: "Origin",
  };
}
