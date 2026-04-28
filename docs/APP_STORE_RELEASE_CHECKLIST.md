# Clarity App Store Release Checklist

This is the lean path for getting Clarity through App Store review without adding unnecessary process.

## Local Build Status

- Bundle ID: `Krunch.Clarity`
- Marketing version: `2.0`
- Build number: `8`
- Release simulator build: passing
- Privacy manifest: included in the built app bundle
- Local StoreKit file: kept outside the app bundle

## Before Upload

- Archive a Release build from Xcode.
- Confirm the archive uses build number `8` or higher.
- Confirm `PrivacyInfo.xcprivacy` is present in the archive app bundle.
- Smoke test these paths on a real device where possible:
  - Daily Practice
  - Reflect capture
  - local Reflect response
  - gated Cloud Tap tools
  - Account purchases screen
  - Restore Purchases
  - Meditation timer
  - Audio playback
  - Calendar
  - Wisdom daily
  - Compassion daily
  - Health permission prompt

## App Store Connect Required Work

- Accept the Paid Apps Agreement.
- Complete banking and tax.
- Create the in-app purchase products in `docs/STOREKIT_SETUP.md`.
- Add Privacy Policy URL.
- Complete App Privacy answers.
- Add app screenshots, description, subtitle, keywords, support URL, age rating, and review notes.
- Use `docs/APP_STORE_CONNECT_METADATA.md` as the starting copy for listing text, review notes, and product descriptions.
- Use `docs/PRIVACY_POLICY_DRAFT.md` as the starting copy for the public privacy policy page.

## Recommended App Store Connect Order

1. Create or confirm the app record for bundle ID `Krunch.Clarity`.
2. Finish Agreements, Tax, and Banking so paid products can be created.
3. Create the `Clarity Reflect` subscription group.
4. Add `clarity_reflect_monthly` and `clarity_reflect_annual` to that group.
5. Give both subscriptions the same access level because they unlock the same feature set.
6. Create the one-time non-consumable support products listed in `docs/STOREKIT_SETUP.md`.
7. Add product localizations, prices, review notes, and review screenshots for each paid product.
8. Wait for product metadata to become available in sandbox, then test purchases.
9. Archive and upload build `8` or higher.
10. Attach the build and required in-app purchases to the same App Review submission.

## Privacy Answers To Keep Aligned

Clarity should not claim tracking unless the app later adds tracking domains or ad tracking.

Likely App Privacy disclosures:

- User ID: anonymous Supabase auth for Cloud Tap.
- User Content: selected redacted text sent only when the user chooses a Cloud Tap response.
- Health and Fitness: accessed from Apple Health for local patterns, if the user grants permission. If not sent off device, say it is not collected.
- Audio Data: recorded and transcribed on device. Do not list as collected unless raw audio is later uploaded.
- Location: used for nearby pilgrimage places. Do not list as collected unless location is sent to a server.
- Purchases: Apple handles payment details. Only disclose developer-collected purchase history if we later send or store transaction/entitlement data server-side.

## Review Notes

Tell Apple:

- Clarity Reflect is the paid feature area.
- Monthly and annual plans unlock Cloud Tap reflection tools.
- One-time support purchases also unlock Clarity Reflect.
- Local audio and raw transcripts stay on device.
- Only selected redacted text is sent when the user chooses a Cloud Tap response.
- Health data is optional and used for local pattern display.
- Support purchases are app support, not charitable donations.

## Testing Purchases Without Real Money

- Local StoreKit testing uses `Clarity.storekit` and does not charge money.
- Sandbox purchases use App Store Connect products and Sandbox Apple Accounts; they do not charge money.
- TestFlight purchases also use the sandbox purchase environment; testers are not charged real money.

Useful Apple docs:

- StoreKit Xcode testing: https://developer.apple.com/documentation/storekit/testing-in-app-purchases-in-xcode
- Sandbox IAP testing: https://developer.apple.com/documentation/StoreKit/testing-in-app-purchases-with-sandbox
- App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- App Review Guidelines: https://developer.apple.com/appstore/resources/approval/guidelines.html

## Still Needed Before Public Release

- Backend entitlement enforcement for paid Cloud Tap requests. See `docs/BACKEND_ENTITLEMENT_ENFORCEMENT.md`.
- App Store Connect product creation and sandbox purchase testing.
- Real device smoke test.
- Privacy Policy page with real support/contact email.
- App screenshots and metadata.
