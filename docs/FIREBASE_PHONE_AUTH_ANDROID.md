# Firebase Phone Auth on Android (fix `missing-client-identifier`)

## What the error means

`firebase_auth/missing-client-identifier` = Firebase could not verify your app via **Play Integrity** or **reCAPTCHA**.  
This is **not** fixed by backend API URL changes.

## Your app (verified on this repo)

| Item | Value |
|------|--------|
| Package | `com.thebabyland` |
| Firebase project | `thebabyland-6db6d` |
| Release SHA-1 | `44:70:15:D9:C2:E0:77:B8:2A:78:8A:ED:5E:70:D2:89:9D:68:2F:BA` |
| Debug SHA-1 | `2B:57:0C:F0:36:13:E3:25:3D:54:BB:6F:36:C8:80:81:FA:09:52:13` |
| Debug SHA-256 | `91:BF:3E:D2:3D:E1:B9:B5:E3:14:CD:84:12:59:EA:6F:ED:06:60:90:41:6A:B4:38:BA:B3:0E:25:6E:98:5D:ED` |
| Release SHA-256 | `C3:CD:8A:8B:A0:CA:29:77:5C:A6:B7:78:2A:BD:09:48:B7:18:92:F9:4C:64:32:CB:28:A1:EB:80:9F:52:3F:65` |

`google-services.json` includes both SHA-1 hashes above for `com.thebabyland`.

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
2. **Project settings → Your apps → Android (`com.thebabyland`)**  
   Add **both** SHA-1 **and** SHA-256 for debug + release (see table above).
3. **Download a new `google-services.json`** → replace `android/app/google-services.json`.
4. [Google Cloud Console](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com?project=thebabyland-6db6d) → enable **Play Integrity API**.
5. **APIs & Services → Credentials** → Firebase Android API key → if restricted, allow app `com.thebabyland` + SHA-1s above.

## App code (otp-v7)

**Critical settings (do not reverse these for real SMS):**

| Flag | Value for real SMS | Why |
|------|--------------------|-----|
| `FIREBASE_FORCE_RECAPTCHA` | `true` | Sideloaded APKs fail Play Integrity |
| `FIREBASE_AUTH_DISABLE_APP_VERIFICATION` | `false` | `true` turns **off** reCAPTCHA and breaks real numbers |

Debug no longer auto-disables app verification (that previously blocked real OTP).

- **`tools/build_apk_release.ps1`** → `APP_BUILD_TAG=otp-v7`, recaptcha on, disable-verification off
- Logcat expect: `"buildTag":"otp-v7"`, `"forceRecaptchaFlow":true`, `"disableAppVerification":false`, `"androidAppId":"...211e354e02114e4a02967c"`
- A **Chrome / Custom Tabs reCAPTCHA** page may open on signup — complete it

### CAPTCHA return must not show "No route defined for /link"

Firebase returns via `/link?deep_link_id=…`. The app now:

- Ignores those routes in `AppRoutes` (pops immediately)
- Sets `flutter_deeplinking_enabled=false` so Flutter does not steal the Auth callback
- Skips resume API reconcile while phone OTP/`isBusy` is true

### SHA-256 (required in Firebase Console for real SMS)

On Android app **`com.thebabyland`** (`1:240228974389:android:211e354e02114e4a02967c`) add:

- Debug SHA-256: `91:BF:3E:D2:3D:E1:B9:B5:E3:14:CD:84:12:59:EA:6F:ED:06:60:90:41:6A:B4:38:BA:B3:0E:25:6E:98:5D:ED`
- Release SHA-256: `C3:CD:8A:8B:A0:CA:29:77:5C:A6:B7:78:2A:BD:09:48:B7:18:92:F9:4C:64:32:CB:28:A1:EB:80:9F:52:3F:65`

(SHA-1s are already in `google-services.json` for this package.)

### Quick test without fixing Integrity/reCAPTCHA

1. Set `FIREBASE_AUTH_DISABLE_APP_VERIFICATION=true` temporarily  
2. Firebase → Phone → **Phone numbers for testing** → `+918769626027` / `123456`  
3. Rebuild, enter that number + code  

```powershell
.\tools\build_apk_release.ps1
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## Quick test without SMS

Firebase Console → Authentication → Phone → **Phone numbers for testing**  
Add `+918769626027` with a fixed 6-digit code, then use that code in the app.

## When you ship on Play Store

1. Confirm release SHA-1 + SHA-256 are in Firebase for `com.thebabyland`.
2. Set `FIREBASE_AUTH_DISABLE_APP_VERIFICATION=false` (or remove) in `assets/.env`.
3. Build Play bundle with `FIREBASE_FORCE_RECAPTCHA=false` once the app is on Play Store (Play Integrity works).
4. Use `.\tools\build_appbundle_release.ps1` for Play upload.