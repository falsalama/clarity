import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type AuthenticatedUser = {
  id: string;
  [key: string]: unknown;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY =
  Deno.env.get("SUPABASE_ANON_KEY") ??
  Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
  "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function json(status: number, body: unknown, headers: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...headers,
    },
  });
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

async function deleteEntitlement(userID: string) {
  const url = new URL("/rest/v1/user_entitlements", SUPABASE_URL);
  url.searchParams.set("user_id", `eq.${userID}`);

  const res = await fetch(url, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Prefer: "return=minimal",
    },
  });

  if (!res.ok) {
    const bodyText = await res.text();
    console.error("[DEBUG] entitlement delete failed", {
      status: res.status,
      bodyText,
    });
    throw new Error("entitlement_delete_failed");
  }
}

async function deleteAuthUser(userID: string) {
  const url = new URL(`/auth/v1/admin/users/${encodeURIComponent(userID)}`, SUPABASE_URL);
  url.searchParams.set("should_soft_delete", "false");

  const res = await fetch(url, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      apikey: SUPABASE_SERVICE_ROLE_KEY,
    },
  });

  if (!res.ok) {
    const bodyText = await res.text();
    console.error("[DEBUG] auth user delete failed", {
      status: res.status,
      bodyText,
    });
    throw new Error("auth_user_delete_failed");
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json(405, { error: "Method not allowed" });
  }

  const requestID = req.headers.get("X-Request-ID") ?? undefined;
  const baseHeaders: HeadersInit = requestID ? { "X-Request-ID": requestID } : {};

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return json(500, { error: "missing_supabase_service_role_config" }, baseHeaders);
  }

  const authCheck = await requireAuthenticatedUser(req, baseHeaders);
  if (!authCheck.ok) {
    return authCheck.response;
  }

  try {
    const userID = authCheck.user.id;

    await deleteEntitlement(userID);
    await deleteAuthUser(userID);

    return json(200, { ok: true, deleted_user_id: userID }, baseHeaders);
  } catch (error) {
    console.error("[DEBUG] delete account failed", {
      requestID: requestID ?? null,
      error: error instanceof Error ? error.message : String(error),
    });

    return json(500, { error: "delete_account_failed" }, baseHeaders);
  }
});
