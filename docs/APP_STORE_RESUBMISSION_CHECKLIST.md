# App Store Connect — resubmission checklist

Use with the Flutter fixes in this release and [`APP_STORE_BACKEND_CONTRACTS.md`](APP_STORE_BACKEND_CONTRACTS.md).

## Before you upload

1. **Backend live** for:
   - `POST /subscriptions/apple/verify` (1-month Pro)
   - Moderation report / block / blocked list
   - `DELETE /users/me`
   - Phone **not** required on signup/profile
2. Bump iOS build number, archive, upload new binary.

## Guideline 2.1(b) — Submit IAP with the binary

1. App Store Connect → your app → **Subscriptions** (or In-App Purchases).
2. Create product ID **`babyland_pro_monthly`** (must match app code).
   - Prefer **Auto-Renewable Subscription**, 1 month duration.
3. Fill localization, review notes, and **App Review screenshot** for the IAP.
4. Submit the IAP **together with** the new app version.

## Guideline 2.1(a) — Purchase sheet

- Demo account for review must **not** already have Pro (`SUBSCRIPTION_ALREADY_ACTIVE` hides the buy CTA).
- On iPad: Profile → Subscription → **Upgrade to Pro** → native App Store sheet.
- After purchase: Upgrade button **hidden**; Insights/AI unlock via `/subscriptions/me`.
- After ~1 month (or sandbox accelerated renewal): status expires → Upgrade returns.

## Guideline 2.3.10 — Screenshots

- Replace all screenshots with **iOS / iPadOS** captures (no Android status bar).
- Do **not** show PhonePe on the iOS Pro paywall (App Store billing only).
- Prefer main features: Home, Tracker, Insights (gated), Community (with overflow Report/Block), Subscription.

## Guideline 5.1.2(i) — Tracking / ATT

App does **not** use App Tracking Transparency or ad/IDFA SDKs.

In App Store Connect → **App Privacy**:

- Answer **No** to tracking (or remove Tracking purposes).
- Do not declare Demographics / Sensitive Info / etc. **for tracking**.
- Align collected-data answers with Firebase Analytics/Crashlytics (app functionality), not advertising tracking.
- Reply to App Review: *“This app does not track users on iOS. App Privacy labels have been updated. ATT is not required.”*

`ios/Runner/PrivacyInfo.xcprivacy` has `NSPrivacyTracking=false` and is included in the Xcode target.

## Guideline 5.1.1(v) — Phone optional

- Signup phone field is optional; Google Add Phone has **Skip for now**.
- Splash no longer forces Add Phone.

## Guideline 5.1.1(v) — Account deletion

- Profile → **Delete Account** → type `DELETE` → permanent delete via `DELETE /users/me`.
- Record a screen capture on a physical device for Review Notes.

## Guideline 1.2 — UGC

- Community post → **⋯** → **Report** and **Block user**.
- Block removes posts from the feed immediately.
- Record screen capture for Review Notes.

## Review Notes template (paste into App Store Connect)

```
Demo account: <email> / <password>
IMPORTANT: This account has NO active subscription so Upgrade to Pro shows the App Store sheet.

IAP product ID: babyland_pro_monthly (submitted with this binary)

Subscription: Profile → Subscription → Upgrade to Pro → Apple purchase sheet.
After purchase, Upgrade is hidden and Pro features unlock for one month.

UGC: Community → ⋯ on a post → Report / Block user (blocked posts disappear immediately).

Account deletion: Profile → Delete Account → type DELETE → confirm.

Phone is optional at signup and on Google complete-profile (Skip for now).

Tracking: App does not track; App Privacy updated; no ATT prompt.
```

Attach screen recordings for: IAP purchase, report+block, account deletion.
