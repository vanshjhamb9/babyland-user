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

Apple Developer already has APNs key **`babylandfilep8`** (Key ID **`FTHTQMX7DW`**, Team **`JLL9Z2C4AZ`**, Sandbox & Production). That key must also exist in **Firebase** — Apple alone is not enough.

1. If you still have the `.p8` for `FTHTQMX7DW`, use it. If not: [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list) → **+** → enable **APNs** → download **`.p8`** once → note new Key ID.
2. [Firebase Console](https://console.firebase.google.com/) → project **`thebabyland-6db6d`**
3. ⚙️ **Project settings** → **Cloud Messaging** → **Apple app configuration**
4. Upload APNs Auth Key for iOS app bundle **`com.thebabyland`**
   - Key ID: `FTHTQMX7DW` (or the new Key ID)
   - Team ID: `JLL9Z2C4AZ`
   - App: `GOOGLE_APP_ID` `1:240228974389:ios:c31a03551c6dc9a502967c`
5. Save → force-quit Babyland on the phone → **Send code** again (no new IPA required for the key alone).

## Confirm checklist (must all be yes)

| Check | Expected |
|--------|----------|
| Firebase → Cloud Messaging → **Production** APNs key | Key ID + Team ID shown (Dev alone is not enough for TestFlight) |
| Firebase → Cloud Messaging → Development APNs key | Optional but OK if present |
| Firebase → Authentication → Sign-in method → Phone | **Enabled** |
| Firebase → Project settings → Your apps → iOS | Bundle `com.thebabyland` |
| After uploading Production key | **Delete app from phone → reinstall from TestFlight** (old installs can keep a bad push registration) |
| Wait | 5–15 minutes after first Production key upload for Apple/Firebase to propagate |

APNs **certificates** can stay empty — Auth Keys are preferred and sufficient.

## Optional: Firebase test numbers (bypass SMS / app verification while fixing)

Authentication → Sign-in method → Phone → **Phone numbers for testing**  
Add e.g. `+916283075131` with a fixed code `123456`, then enter that code in the app (no SMS needed).

## Not the cause of this OTP error

- SHA-1 / SHA-256 (Android only)
- Play Services (Android only)
- Codemagic IPA / TestFlight install (already working if you see this screen)
- `FIREBASE_APP_CHECK_ENABLED=false` on the TestFlight build (App Check is off; OK for now)
