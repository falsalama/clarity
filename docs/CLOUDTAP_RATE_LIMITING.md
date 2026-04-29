# Cloud Tap Entitlement And Rate Limiting

Cloud Tap must be protected server-side. The app UI gate is useful for UX, but it is not enough to protect paid model calls.

## Required Deployment Order

1. Run `supabase/sql/cloudtap_rate_limits.sql` in the Supabase SQL editor.
2. Confirm the Cloud Tap Edge Functions have `SUPABASE_SERVICE_ROLE_KEY` set.
3. Patch every paid Cloud Tap function before the OpenAI call:
   - authenticate the Supabase user JWT
   - check `public.user_entitlements`
   - consume the rate limit
   - only then call OpenAI

## Recommended Limits

These limits are deliberately generous. They are not there to ration normal use. They are there to stop runaway abuse, a hijacked session, or a bug that loops paid model calls.

- `RATE_LIMIT_PER_HOUR`: `60`
- `RATE_LIMIT_PER_DAY`: `250`

Set these as Edge Function secrets if you want to override the defaults.

## Functions To Protect

The paid Cloud Tap functions are:

- `cloudtap-reflect`
- `cloudtap-clarity-perspective`
- `cloudtap-options`
- `cloudtap-questions`
- `cloudtap-talkitthrough`

The exported `cloudtap-reflect` source already includes authentication and entitlement checks. The exported sources for `cloudtap-clarity-perspective`, `cloudtap-options`, `cloudtap-questions`, and `cloudtap-talkitthrough` must receive the same server-side entitlement check before release.

## Shared Edge Function Helper

Add this beside the existing Supabase constants in each paid Cloud Tap function:

```ts
type RateLimitResult = {
  allowed: boolean;
  remaining: number;
  reset_at: string;
};

const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const RATE_LIMIT_PER_HOUR = parseInt(Deno.env.get("RATE_LIMIT_PER_HOUR") ?? "60", 10);
const RATE_LIMIT_PER_DAY = parseInt(Deno.env.get("RATE_LIMIT_PER_DAY") ?? "250", 10);
```

Add this helper after `requireReflectEntitlement`:

```ts
async function consumeRateLimit(
  userID: string,
  endpoint: string,
  headers: HeadersInit = {},
) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return {
      ok: false as const,
      response: json(500, { error: "missing_rate_limit_config" }, headers),
    };
  }

  const checks = [
    { bucket: `${endpoint}:hour`, limit: RATE_LIMIT_PER_HOUR, windowSeconds: 3600 },
    { bucket: `${endpoint}:day`, limit: RATE_LIMIT_PER_DAY, windowSeconds: 86400 },
  ];

  for (const check of checks) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/consume_cloudtap_rate_limit`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        p_user_id: userID,
        p_bucket: check.bucket,
        p_limit: check.limit,
        p_window_seconds: check.windowSeconds,
      }),
    });

    if (!res.ok) {
      const bodyText = await res.text();
      console.error("[DEBUG] rate limit check failed", {
        endpoint,
        status: res.status,
        bodyText,
      });

      return {
        ok: false as const,
        response: json(500, { error: "rate_limit_check_failed" }, headers),
      };
    }

    const rows = (await res.json()) as RateLimitResult[];
    const row = rows[0];

    if (!row?.allowed) {
      return {
        ok: false as const,
        response: json(
          429,
          { error: "rate_limited", reset_at: row?.reset_at ?? null },
          {
            ...headers,
            ...(row?.reset_at ? { "X-RateLimit-Reset": row.reset_at } : {}),
          },
        ),
      };
    }
  }

  return { ok: true as const };
}
```

Call it after entitlement succeeds and before parsing/calling OpenAI:

```ts
const rateLimit = await consumeRateLimit(authCheck.user.id, "cloudtap-reflect", baseHeaders);
if (!rateLimit.ok) {
  return rateLimit.response;
}
```

Change the endpoint name per function:

- `cloudtap-reflect`
- `cloudtap-clarity-perspective`
- `cloudtap-options`
- `cloudtap-questions`
- `cloudtap-talkitthrough`

## Why This Shape

This is the normal secure pattern:

- Apple/StoreKit proves purchase to the app.
- The app syncs entitlement to Supabase.
- Supabase Edge Functions independently enforce entitlement before expensive model calls.
- Rate limiting happens server-side by Supabase user ID, so a modified client cannot bypass it.
- The service role key stays only in Supabase secrets, never in the app.
