# Firebase Phone Auth — iOS (TestFlight)

## Current known error (Aug 2026)

```
firebase_auth/recaptcha-sdk-not-linked
The reCAPTCHA SDK is not linked to your app.
```

This is **not** an APNs key problem anymore (Production + Development keys are uploaded).

It means **reCAPTCHA Enterprise / SMS defense was turned on** for project `thebabyland-6db6d`, so the iOS SDK expects the Recaptcha Enterprise library. Babyland does not ship that SDK. Phone OTP fails until Enterprise enforcement is **OFF**.

### Fix A — Firebase Console (try first)

1. [Firebase Console](https://console.firebase.google.com/project/thebabyland-6db6d/authentication/settings) → **Authentication** → **Settings** → **reCAPTCHA**
2. **Phone authentication enforcement mode** must be **`OFF`** (not `AUDIT`, not `ENFORCE`)
3. Click **Save**
4. Force-quit Babyland → **Send code** again  
   **No new TestFlight build required for this console change.**

`AUDIT` still triggers reCAPTCHA Enterprise fallback and causes `recaptcha-sdk-not-linked` on iOS without the Enterprise SDK.

### Fix B — Identity Platform API (if Console toggle does not stick)

Open this link while logged into the Google account that owns the Firebase project (replace is already filled for Babyland):

[Identity Platform `projects.updateConfig` (API Explorer)](https://cloud.google.com/identity-platform/docs/reference/rest/v2/projects/updateConfig?apix_params=%7B%22name%22%3A%22projects%2Fthebabyland-6db6d%2Fconfig%22%2C%22updateMask%22%3A%22recaptchaConfig%22%2C%22resource%22%3A%7B%22recaptchaConfig%22%3A%7B%22phoneEnforcementState%22%3A%22OFF%22%2C%22useSmsTollFraudProtection%22%3Afalse%7D%7D%7D)

1. Confirm **name** = `projects/thebabyland-6db6d/config`
2. Confirm **updateMask** = `recaptchaConfig`
3. Request body includes:
   ```json
   {
     "recaptchaConfig": {
       "phoneEnforcementState": "OFF",
       "useSmsTollFraudProtection": false
     }
   }
   ```
4. Click **Execute** (authorize Google Cloud if asked)
5. Force-quit the app → **Send code** again

This is the fix reported by FlutterFire / Firebase iOS SDK issues for `ERROR_RECAPTCHA_SDK_NOT_LINKED`.

### Optional unblock while fixing

Authentication → Sign-in method → Phone → **Phone numbers for testing**  
Add `+916283075131` / code `123456`.

---

## APNs checklist (already done for Babyland)

| Check | Expected |
|--------|----------|
| Cloud Messaging → **Production** APNs auth key | Key `FTHTQMX7DW`, Team `JLL9Z2C4AZ` |
| Cloud Messaging → Development APNs auth key | Same key OK |
| APNs certificates | Can stay empty (Auth Key is enough) |
| Authentication → Phone provider | Enabled |
| Bundle ID | `com.thebabyland` |

---

## How iOS Phone Auth works

1. **Primary:** silent push via **APNs** (no reCAPTCHA UI).
2. **Fallback:** reCAPTCHA — either classic (Safari) or Enterprise (requires SDK).

If Enterprise enforcement is ON without the SDK → `recaptcha-sdk-not-linked`.

---

## Not the cause of this specific error

- Missing Production APNs key (you already uploaded it)
- SHA-1 / Play Services (Android only)
- Empty APNs certificates section
