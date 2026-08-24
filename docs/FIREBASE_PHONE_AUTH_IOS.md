# Firebase Phone Auth — iOS (TestFlight)

## Symptom

TestFlight build opens, but **Send OTP / Send code** shows:

> Security verification (reCAPTCHA) failed …

Older builds also mentioned **SHA-1** and **Play Services**. Those are **Android** checks and do **not** apply to iPhone. Ignore them.

## How iOS Phone Auth works

1. **Primary:** silent push via **APNs** (no reCAPTCHA UI).
2. **Fallback:** reCAPTCHA in Safari / in-app browser.

If no APNs key is uploaded to Firebase, OTP almost always falls back to reCAPTCHA and often fails on TestFlight.

## Required console fix (no app rebuild needed for this alone)

1. [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list) → **+**
2. Enable **Apple Push Notifications service (APNs)** → Continue → Register → download **`.p8`** once.
3. Note **Key ID** and **Team ID** (`JLL9Z2C4AZ` for Babyland).
4. [Firebase Console](https://console.firebase.google.com/) → project **`thebabyland-6db6d`**
5. ⚙️ **Project settings** → **Cloud Messaging** → **Apple app configuration**
6. Upload the APNs Auth Key for iOS app bundle **`com.thebabyland`**
   (`GOOGLE_APP_ID` `1:240228974389:ios:c31a03551c6dc9a502967c`).

## Also verify

| Check | Expected |
|--------|----------|
| Firebase → Authentication → Sign-in method → Phone | Enabled |
| Firebase → Project settings → Your apps → iOS | Bundle `com.thebabyland` |
| `ios/Runner/GoogleService-Info.plist` | Same bundle + project |
| App Store Connect app | Bundle `com.thebabyland` (Babyland User) |
| Push capability | Enabled on App ID + profile (already done for TestFlight) |

## Optional: Firebase test numbers (bypass SMS while fixing APNs)

Authentication → Sign-in method → Phone → **Phone numbers for testing**  
Add e.g. `+91XXXXXXXXXX` with a fixed code `123456`.

## Not the cause of this OTP error

- SHA-1 / SHA-256 (Android only)
- Play Services (Android only)
- Codemagic IPA / TestFlight install (already working if you see this screen)
- `FIREBASE_APP_CHECK_ENABLED=false` on the TestFlight build (App Check is off; OK for now)
