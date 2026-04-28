# Clarity StoreKit Setup

The app code and local StoreKit file currently expect these exact product IDs.

## Subscription Products

Create one subscription group:

- `Clarity Reflect`

Create these auto-renewable subscriptions inside that group:

- Product ID: `clarity_reflect_monthly`
- Reference name: `Clarity Reflect Monthly`
- Duration: 1 month
- Suggested price: GBP 4.99

- Product ID: `clarity_reflect_annual`
- Reference name: `Clarity Reflect Annual`
- Duration: 1 year
- Suggested price: GBP 49.99

The annual plan should remain lower over a year than paying monthly.

## One-Time Support Products

Create these as non-consumable in-app purchases:

- Product ID: `support_clarity`
- Reference name: `Support Clarity`
- Suggested price: GBP 14.99

- Product ID: `support_clarity_100`
- Reference name: `Support Clarity 100`
- Suggested price: GBP 99.99

- Product ID: `support_clarity_500`
- Reference name: `Support Clarity 500`
- Suggested price: GBP 499.99

- Product ID: `support_clarity_1000`
- Reference name: `Support Clarity 1000`
- Suggested price: GBP 999.99

## Why These Are Non-Consumable

These support purchases are intended to restore across devices on the same Apple ID and unlock Clarity Reflect permanently for that Apple ID. They are not consumables and should not be described as charitable donations.

## Local Testing

Local testing uses:

- `Clarity.storekit`

The shared `Clarity` scheme points to this file for local StoreKit testing. This lets purchase UI, transaction state, restore behavior, and entitlement gating be tested without App Store Connect and without real money.

## App Store Connect Testing

After the products exist in App Store Connect:

- Use Sandbox Apple Accounts for development builds.
- Use TestFlight for near-production purchase testing.
- Confirm monthly unlocks Clarity Reflect.
- Confirm annual unlocks Clarity Reflect.
- Confirm each support tier unlocks Clarity Reflect.
- Confirm Restore Purchases restores subscriptions and non-consumable support purchases.
- Confirm unsubscribed users still have the free app features and see locked paid Reflect tools.

## Supabase Entitlement Sync

Paid Cloud Tap functions are protected by `public.user_entitlements`. Apple purchases must sync to Supabase before paid model calls can run.

Deploy this Edge Function:

- `supabase/functions/verify-apple-entitlement/index.ts`

Set these Supabase Edge Function secrets:

- `APPLE_ISSUER_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY`
- `APPLE_BUNDLE_ID` = `Krunch.Clarity`
- `SUPABASE_SERVICE_ROLE_KEY`

The iOS app sends StoreKit's verified transaction JWS to `verify-apple-entitlement`. The function checks the transaction with Apple's App Store Server API, validates bundle ID/product/expiry, and upserts `public.user_entitlements`.

For TestFlight and sandbox purchases, Apple transaction lookup uses the sandbox server when the transaction environment is Sandbox. Live purchases use production.

## App Code References

- Billing store: `Clarity/Core/Billing/ClarityReflectStore.swift`
- Account UI: `Clarity/Features/Profile/ClarityReflectView.swift`
- Reflect gate: `Clarity/Features/Reflect/TurnDetailView.swift`
