import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type AuthenticatedUser = {
  id: string;
  [key: string]: unknown;
};

type VerifyEntitlementRequest = {
  signedTransactionInfo?: string;
  transactionId?: string;
};

type DecodedTransaction = {
  bundleId?: string;
  environment?: string;
  expiresDate?: number | string;
  originalTransactionId?: string | number;
  productId?: string;
  revocationDate?: number | string;
  transactionId?: string | number;
  type?: string;
  [key: string]: unknown;
};

const SUBSCRIPTION_PRODUCT_IDS = new Set([
  "clarity_reflect_monthly",
  "clarity_reflect_annual",
]);

const SUPPORT_PRODUCT_IDS = new Set([
  "support_clarity",
  "support_clarity_100",
  "support_clarity_500",
  "support_clarity_1000",
]);

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY =
  Deno.env.get("SUPABASE_ANON_KEY") ??
  Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
  "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const APPLE_ISSUER_ID = Deno.env.get("APPLE_ISSUER_ID") ?? "";
const APPLE_KEY_ID = Deno.env.get("APPLE_KEY_ID") ?? "";
const APPLE_PRIVATE_KEY = Deno.env.get("APPLE_PRIVATE_KEY") ?? "";
const APPLE_BUNDLE_ID = Deno.env.get("APPLE_BUNDLE_ID") ?? "Krunch.Clarity";

function json(status: number, body: unknown, headers: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...headers,
    },
  });
}

function badRequest(message: string, headers: HeadersInit = {}) {
  return json(400, { error: message }, headers);
}

async function requireAuthenticatedUser(req: Request, headers: HeadersInit = {}) {
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!authHeader.startsWith("Bearer ")) {
    return {
      ok: false as const,
      response: json(401, { error: "missing_bearer_token" }, headers),
    };
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return {
      ok: false as const,
      response: json(500, { error: "missing_supabase_auth_config" }, headers),
    };
  }

  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    method: "GET",
    headers: {
      Authorization: authHeader,
      apikey: SUPABASE_ANON_KEY,
    },
  });

  if (!res.ok) {
    return {
      ok: false as const,
      response: json(401, { error: "invalid_user_jwt" }, headers),
    };
  }

  const user = (await res.json()) as AuthenticatedUser;

  if (!user?.id) {
    return {
      ok: false as const,
      response: json(401, { error: "missing_user_id" }, headers),
    };
  }

  return {
    ok: true as const,
    user,
  };
}

function base64URLToBytes(value: string): Uint8Array {
  const base64 = value
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(value.length / 4) * 4, "=");

  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
}

function bytesToBase64URL(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function textToBase64URL(value: string): string {
  return bytesToBase64URL(new TextEncoder().encode(value));
}

function decodeTransactionPayload(jws: string): DecodedTransaction {
  const parts = jws.split(".");
  if (parts.length !== 3) {
    throw new Error("invalid_jws");
  }

  const payloadJSON = new TextDecoder().decode(base64URLToBytes(parts[1]));
  return JSON.parse(payloadJSON) as DecodedTransaction;
}

function pemToPKCS8Bytes(pem: string): Uint8Array {
  const normalized = pem.replace(/\\n/g, "\n");
  const body = normalized
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");

  if (!body) {
    throw new Error("missing_private_key_body");
  }

  return Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
}

async function createAppStoreJWT(): Promise<string> {
  if (!APPLE_ISSUER_ID || !APPLE_KEY_ID || !APPLE_PRIVATE_KEY || !APPLE_BUNDLE_ID) {
    throw new Error("missing_apple_server_api_config");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "ES256",
    kid: APPLE_KEY_ID,
    typ: "JWT",
  };
  const payload = {
    iss: APPLE_ISSUER_ID,
    iat: now,
    exp: now + 600,
    aud: "appstoreconnect-v1",
    bid: APPLE_BUNDLE_ID,
  };

  const signingInput = [
    textToBase64URL(JSON.stringify(header)),
    textToBase64URL(JSON.stringify(payload)),
  ].join(".");

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToPKCS8Bytes(APPLE_PRIVATE_KEY),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${bytesToBase64URL(new Uint8Array(signature))}`;
}

function transactionIDFrom(payload: VerifyEntitlementRequest): string {
  if (payload.transactionId) {
    return String(payload.transactionId).trim();
  }

  if (!payload.signedTransactionInfo) {
    return "";
  }

  const decoded = decodeTransactionPayload(payload.signedTransactionInfo);
  return String(decoded.transactionId ?? decoded.originalTransactionId ?? "").trim();
}

function environmentFrom(payload: VerifyEntitlementRequest): "Sandbox" | "Production" | null {
  if (!payload.signedTransactionInfo) {
    return null;
  }

  try {
    const decoded = decodeTransactionPayload(payload.signedTransactionInfo);
    return decoded.environment === "Sandbox" ? "Sandbox" : "Production";
  } catch {
    return null;
  }
}

async function fetchAppleTransactionInfo(
  transactionId: string,
  preferredEnvironment: "Sandbox" | "Production" | null,
): Promise<{ signedTransactionInfo: string; environment: "Sandbox" | "Production" }> {
  const token = await createAppStoreJWT();
  const environments: ("Sandbox" | "Production")[] =
    preferredEnvironment === "Sandbox" ? ["Sandbox", "Production"] : ["Production", "Sandbox"];

  let lastStatus = 0;
  let lastBody = "";

  for (const environment of environments) {
    const host =
      environment === "Sandbox"
        ? "https://api.storekit-sandbox.itunes.apple.com"
        : "https://api.storekit.itunes.apple.com";
    const url = `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`;

    const res = await fetch(url, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
      },
    });

    if (res.ok) {
      const body = (await res.json()) as { signedTransactionInfo?: string };
      if (!body.signedTransactionInfo) {
        throw new Error("missing_signed_transaction_info");
      }
      return { signedTransactionInfo: body.signedTransactionInfo, environment };
    }

    lastStatus = res.status;
    lastBody = await res.text();
  }

  console.error("[DEBUG] apple transaction lookup failed", {
    transactionId,
    lastStatus,
    lastBody,
  });

  throw new Error("apple_transaction_lookup_failed");
}

function dateFromAppleMillis(value: unknown): Date | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value);
  }

  if (typeof value === "string" && value.trim()) {
    const numeric = Number(value);
    if (Number.isFinite(numeric)) {
      return new Date(numeric);
    }

    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) {
      return new Date(parsed);
    }
  }

  return null;
}

function validateAccess(decoded: DecodedTransaction) {
  const bundleID = String(decoded.bundleId ?? "");
  if (bundleID !== APPLE_BUNDLE_ID) {
    return {
      ok: false as const,
      status: 403,
      error: "bundle_mismatch",
    };
  }

  const productID = String(decoded.productId ?? "");
  const isSubscription = SUBSCRIPTION_PRODUCT_IDS.has(productID);
  const isSupport = SUPPORT_PRODUCT_IDS.has(productID);

  if (!isSubscription && !isSupport) {
    return {
      ok: false as const,
      status: 403,
      error: "unsupported_product",
    };
  }

  if (decoded.revocationDate) {
    return {
      ok: false as const,
      status: 403,
      error: "transaction_revoked",
    };
  }

  if (isSupport) {
    return {
      ok: true as const,
      productID,
      originalTransactionID: String(
        decoded.originalTransactionId ?? decoded.transactionId ?? "",
      ),
      expiresAt: null as string | null,
    };
  }

  const expiry = dateFromAppleMillis(decoded.expiresDate);
  if (!expiry || expiry.getTime() <= Date.now()) {
    return {
      ok: false as const,
      status: 403,
      error: "subscription_not_active",
    };
  }

  return {
    ok: true as const,
    productID,
    originalTransactionID: String(
      decoded.originalTransactionId ?? decoded.transactionId ?? "",
    ),
    expiresAt: expiry.toISOString(),
  };
}

async function existingPermanentSupport(userID: string) {
  const url = new URL("/rest/v1/user_entitlements", SUPABASE_URL);
  url.searchParams.set("select", "product_id,expires_at,reflect_access");
  url.searchParams.set("user_id", `eq.${userID}`);
  url.searchParams.set("limit", "1");

  const res = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Accept: "application/json",
    },
  });

  if (!res.ok) return false;

  const rows = (await res.json()) as {
    product_id?: string | null;
    expires_at?: string | null;
    reflect_access?: boolean | null;
  }[];
  const row = rows[0];

  return (
    row?.reflect_access === true &&
    !row.expires_at &&
    !!row.product_id &&
    SUPPORT_PRODUCT_IDS.has(row.product_id)
  );
}

async function upsertEntitlement(
  userID: string,
  entitlement: {
    productID: string;
    originalTransactionID: string;
    expiresAt: string | null;
  },
) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("missing_supabase_service_role_config");
  }

  const keepPermanentSupport =
    entitlement.expiresAt !== null && (await existingPermanentSupport(userID));

  const body = {
    user_id: userID,
    reflect_access: true,
    source: "apple_storekit",
    product_id: keepPermanentSupport ? "support_clarity" : entitlement.productID,
    original_transaction_id: entitlement.originalTransactionID,
    expires_at: keepPermanentSupport ? null : entitlement.expiresAt,
    updated_at: new Date().toISOString(),
  };

  const url = new URL("/rest/v1/user_entitlements", SUPABASE_URL);
  url.searchParams.set("on_conflict", "user_id");

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const bodyText = await res.text();
    console.error("[DEBUG] entitlement upsert failed", {
      status: res.status,
      bodyText,
    });
    throw new Error("entitlement_upsert_failed");
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json(405, { error: "Method not allowed" });
  }

  const requestID = req.headers.get("X-Request-ID") ?? undefined;
  const baseHeaders: HeadersInit = requestID ? { "X-Request-ID": requestID } : {};

  const authCheck = await requireAuthenticatedUser(req, baseHeaders);
  if (!authCheck.ok) {
    return authCheck.response;
  }

  let payload: VerifyEntitlementRequest;
  try {
    payload = (await req.json()) as VerifyEntitlementRequest;
  } catch {
    return badRequest("invalid_json", baseHeaders);
  }

  let transactionId = "";
  let preferredEnvironment: "Sandbox" | "Production" | null = null;

  try {
    transactionId = transactionIDFrom(payload);
    preferredEnvironment = environmentFrom(payload);
  } catch {
    return badRequest("invalid_signed_transaction_info", baseHeaders);
  }

  if (!transactionId) {
    return badRequest("transaction_id_required", baseHeaders);
  }

  try {
    const verified = await fetchAppleTransactionInfo(transactionId, preferredEnvironment);
    const decoded = decodeTransactionPayload(verified.signedTransactionInfo);
    const access = validateAccess(decoded);

    if (!access.ok) {
      return json(access.status, { error: access.error }, baseHeaders);
    }

    await upsertEntitlement(authCheck.user.id, access);

    return json(
      200,
      {
        ok: true,
        reflect_access: true,
        product_id: access.productID,
        expires_at: access.expiresAt,
        environment: verified.environment,
      },
      baseHeaders,
    );
  } catch (error) {
    console.error("[DEBUG] verify apple entitlement failed", {
      requestID: requestID ?? null,
      error: error instanceof Error ? error.message : String(error),
    });

    return json(500, { error: "verify_apple_entitlement_failed" }, baseHeaders);
  }
});
