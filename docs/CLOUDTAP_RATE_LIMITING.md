# Cloud Tap Entitlement And Rate Limiting

Cloud Tap must be protected server-side. The app UI gate is useful for UX, but it is not enough to protect paid model calls.

## Required Deployment Order

1. Run `supabase/sql/cloudtap_rate_limits.sql` in the Supabase SQL editor.
2. Confirm these Supabase secrets are set for the Cloud Tap Edge Functions:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` or `SUPABASE_PUBLISHABLE_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
3. Deploy the Cloud Tap Edge Functions from `supabase/functions/`.

## Recommended Limits

These limits are deliberately generous. They are not there to ration normal use. They are there to stop runaway abuse, a hijacked session, or a bug that loops paid model calls.

- `CLOUDTAP_RATE_LIMIT_PER_HOUR`: `60`
- `CLOUDTAP_RATE_LIMIT_PER_DAY`: `250`

The functions also accept the older fallback names `RATE_LIMIT_PER_HOUR` and `RATE_LIMIT_PER_DAY`.

## Functions To Protect

The paid Cloud Tap functions are:

- `cloudtap-reflect`
- `cloudtap-clarity-perspective`
- `cloudtap-options`
- `cloudtap-questions`
- `cloudtap-talkitthrough`

All five checked-in functions now:

- authenticate the Supabase user JWT
- check `public.user_entitlements`
- consume a shared Cloud Tap hourly bucket
- consume a shared Cloud Tap daily bucket
- only then call OpenAI

The bucket is intentionally shared across paid Cloud Tap, not split per button. That prevents a modified client from multiplying the allowance by cycling through endpoints.

## Why This Shape

This is the normal secure pattern:

- Apple/StoreKit proves purchase to the app.
- The app syncs entitlement to Supabase.
- Supabase Edge Functions independently enforce entitlement before expensive model calls.
- Rate limiting happens server-side by Supabase user ID, so a modified client cannot bypass it.
- The service role key stays only in Supabase secrets, never in the app.
