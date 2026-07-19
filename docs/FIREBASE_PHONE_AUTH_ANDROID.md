# Firebase Phone Auth on Android (fix `missing-client-identifier`)

## What the error means

`firebase_auth/missing-client-identifier` = Firebase could not verify your app via **Play Integrity** or **reCAPTCHA**.  
This is **not** fixed by backend API URL changes.

## Your app (verified on this repo)

| Item | Value |
|------|--------|
| Package | `com.babyland` |
| Firebase project | `thebabyland-6db6d` |
| Release signing | **Debug keystore** (`signingConfig debug`) |
| SHA-1 (debug + release APK) | `2B:57:0C:F0:36:13:E3:25:3D:54:BB:6F:36:C8:80:81:FA:09:52:13` |
| SHA-256 | `91:BF:3E:D2:3D:E1:B9:B5:E3:14:CD:84:12:59:EA:6F:ED:06:60:90:41:6A:B4:38:BA:B3:0E:25:6E:98:5D:ED` |

`google-services.json` already contains SHA-1 `2b570cf0…5213` — matches the keystore above.

## App Check (optional — do not enable until ready)

Your log showed `App attestation failed` (403) because App Check was on **without** a registered **debug token**.

**otp-v4 builds disable App Check by default** (`FIREBASE_APP_CHECK_ENABLED=false`) so Phone Auth is not blocked.

If you enable App Check later:

1. Build with `--dart-define=FIREBASE_APP_CHECK_ENABLED=true` and `FIREBASE_APP_CHECK_DEBUG=true`.
2. Copy the debug token from logcat → Firebase → App Check → **Manage debug tokens**.
3. Or set App Check → **APIs** → **Authentication** → **Unenforced**.

## reCAPTCHA on sideloaded APK (main fix in otp-v4)

Play Integrity fails outside Play Store → Firebase uses **reCAPTCHA in Chrome Custom Tabs**.

**otp-v4 adds:**

- `androidx.browser:browser` dependency
- Android 11+ `<queries>` for `https` + Custom Tabs in `AndroidManifest.xml`

**Also check Google Cloud (common cause of this exact error):**

[Credentials](https://console.cloud.google.com/apis/credentials?project=thebabyland-6db6d) → Android API key (`AIzaSy…` from `google-services.json`) → if **Application restrictions** block the browser used by reCAPTCHA, set to **None** temporarily or add the correct restrictions.

## Firebase Console checklist

1. **Authentication → Sign-in method → Phone** → **Enabled**.
2. **Project settings → Your apps → Android (`com.babyland`)**  
   Add **both** SHA-1 **and** SHA-256 (run `.\tools\print_firebase_sha.ps1`).
3. **Download a new `google-services.json`** → replace `android/app/google-services.json`.
4. [Google Cloud Console](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com?project=thebabyland-6db6d) → enable **Play Integrity API**.
5. **APIs & Services → Credentials** → Firebase Android API key → if restricted, allow app `com.babyland` + SHA-1 above.

## App code (already in repo)

- **Release APK** forces `forceRecaptchaFlow: true` in `main.dart` (no extra flags required).
- **`tools/build_apk_release.ps1`** passes `APP_BUILD_TAG=otp-v4`.
- Rebuild and **reinstall** after changing `google-services.json` or SHA keys.
- Logcat: `adb logcat | findstr "AGENT_DEBUG FirebasePhoneAuth Recaptcha"` — expect `"buildTag":"otp-v4"`, `"forceRecaptchaFlow":true`, `"App Check skipped"`. A **reCAPTCHA browser tab** may open briefly when you tap signup.

### SHA-256 (required in Firebase Console)

Add this in Project settings → Android app (in addition to SHA-1):

`91:BF:3E:D2:3D:E1:B9:B5:E3:14:CD:84:12:59:EA:6F:ED:06:60:90:41:6A:B4:38:BA:B3:0E:25:6E:98:5D:ED`

Then **download a new `google-services.json`** and rebuild.

### Quick test without fixing Integrity/reCAPTCHA

Firebase Console → Authentication → Phone → **Phone numbers for testing** → add `+918769626027` with code `123456`, then enter `123456` in the app.

```powershell
.\tools\build_apk_release.ps1
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## Quick test without SMS

Firebase Console → Authentication → Phone → **Phone numbers for testing**  
Add `+918769626027` with a fixed 6-digit code, then use that code in the app (works best in **debug** builds).

## When you ship on Play Store

1. Create a **release keystore** and register its SHA-1 + SHA-256 in Firebase.
2. Build with that keystore (not `debug`).
3. Set `FIREBASE_FORCE_RECAPTCHA=false` in `assets/.env` or `--dart-define=FIREBASE_FORCE_RECAPTCHA=false`.
