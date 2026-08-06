# Critical: Firebase Android package mismatch (Phone OTP)

## Verified from Firebase Console screenshot

| Platform | Console package / bundle | App ID |
|----------|--------------------------|--------|
| **Android (wrong)** | `com.babyland` | `1:240228974389:android:68e3b0eaf2de15d702967c` |
| **iOS (correct)** | `com.thebabyland` | `1:240228974389:ios:c31a03551c6dc9a502967c` |

## What the app builds as

| Item | Value |
|------|--------|
| `applicationId` | `com.thebabyland` |
| Local `google-services.json` package | `com.thebabyland` (edited to match app, **same App ID as Console’s `com.babyland`**) |
| Android API key | `AIzaSyDdepgOWXZqL0r04QMH96ka-cIieEqqZ8c` |
| iOS API key | `AIzaSyD94UmjfGsJlhUnIK2aaSohEMBP70pexD0` |

Editing `package_name` inside `google-services.json` does **not** change the package registered in Firebase. Phone Auth / reCAPTCHA / Play Integrity still validate against Console’s **`com.babyland`**, so release OTP fails with `missing-client-identifier`.

## Fix (required for production OTP)

### 1. Add a new Android app in Firebase Console

1. [Project settings → Your apps](https://console.firebase.google.com/project/thebabyland-6db6d/settings/general) → **Add app** → **Android**
2. **Android package name:** `com.thebabyland` (must match exactly)
3. App nickname: `Babyland Android` (optional)
4. Register app

### 2. Add SHA fingerprints on that new Android app

**Debug**

- SHA-1: `2B:57:0C:F0:36:13:E3:25:3D:54:BB:6F:36:C8:80:81:FA:09:52:13`
- SHA-256: `91:BF:3E:D2:3D:E1:B9:B5:E3:14:CD:84:12:59:EA:6F:ED:06:60:90:41:6A:B4:38:BA:B3:0E:25:6E:98:5D:ED`

**Release** (`android/upload-keystore.jks`)

- SHA-1: `44:70:15:D9:C2:E0:77:B8:2A:78:8A:ED:5E:70:D2:89:9D:68:2F:BA`
- SHA-256: `C3:CD:8A:8B:A0:CA:29:77:5C:A6:B7:78:2A:BD:09:48:B7:18:92:F9:4C:64:32:CB:28:A1:EB:80:9F:52:3F:65`

### 3. Download config into the repo

1. Download **`google-services.json`** from the **new** `com.thebabyland` Android app
2. Replace `android/app/google-services.json`
3. Confirm the new file has a **different** `mobilesdk_app_id` ending (not `…68e3b0eaf2de15d702967c` unless Firebase reused — usually new)
4. Update Dart options:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=thebabyland-6db6d
```

Or manually set `DefaultFirebaseOptions.android.appId` / `apiKey` from the new JSON.

### 4. Rebuild release and test OTP

```powershell
.\tools\verify_firebase_android_keys.ps1
.\tools\build_apk_release.ps1
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

**OTP test checklist**

1. Firebase → Authentication → Sign-in method → **Phone** enabled  
2. (QA) Authentication → Phone → **Phone numbers for testing** → e.g. `+918769626027` / `123456`  
3. Sign up → OTP screen → enter code → should call `/auth/verify-otp` with Firebase `idToken`  
4. Log in with same email/password → must succeed (no 403 “verify your phone”)  
5. Logcat: `adb logcat | findstr "AGENT_DEBUG FirebasePhoneAuth"` → expect `codeSent`, not `missing-client-identifier`

### Optional: keep old `com.babyland` app

You can leave the old Android app in the project for legacy builds, but **production / Play (`com.thebabyland`) must use the new app’s JSON**.

## Local audit command

```powershell
.\tools\verify_firebase_android_keys.ps1
```
