# Backend Entitlement Enforcement

This is the main technical item still needed before relying on paid Clarity Reflect in production.

## Current State

The iOS app has a user-facing StoreKit gate. That is good for UX, but it is not enough protection for paid Cloud Tap usage by itself.

Cloud Tap endpoints currently trust an authenticated Supabase request. If an endpoint does not verify paid entitlement server-side, a determined user could call the endpoint directly and bypass the app UI.

## Required Production Rule

Every paid Cloud Tap endpoint should check the Supabase user before running model work:

- `cloudtap-reflect`
- `cloudtap-options`
- `cloudtap-questions`
- `cloudtap-clarity-perspective`
- `cloudtap-talkitthrough`

Free content endpoints can remain public or anon-key protected:

- `practice-steps`
- `focus-steps`
- `reflect-steps`
- `wisdom-steps`
- `compassion-steps`
- calendar/read-only content endpoints

## Recommended Shape

Create a Supabase table such as `user_entitlements`:

- `user_id uuid primary key`
- `reflect_access boolean not null default false`
- `source text`
- `product_id text`
- `original_transaction_id text`
- `expires_at timestamptz`
- `updated_at timestamptz not null default now()`

For subscriptions:

- Access is valid only when `expires_at` is in the future.

For non-consumable support purchases:

- Access can remain valid with no expiry.

## Verification Flow

1. iOS completes a StoreKit purchase.
2. iOS sends the verified transaction JWS or transaction identifier to a Supabase function.
3. The Supabase function verifies it with Apple.
4. Supabase updates `user_entitlements` for the authenticated Supabase user.
5. Paid Cloud Tap functions check `user_entitlements` before model work.

Implemented source file:

- `supabase/functions/verify-apple-entitlement/index.ts`

The app-side caller is in:

- `Clarity/Core/Billing/ClarityReflectStore.swift`

## Temporary Test Option

Before full Apple server verification is wired, a development-only entitlement table can be manually enabled for your own Supabase user. Do not ship paid Cloud Tap publicly with only a manual or client-side entitlement check.

## Client-Side Gate Still Matters

Keep the iOS gate in place. It gives normal users the correct purchase flow and prevents accidental access. The server gate is the cost and abuse protection.
