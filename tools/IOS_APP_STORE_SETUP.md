# Babyland — iOS App Store setup

Android is published as **`com.thebabyland`**. iOS is now configured to match.  
**You must use a Mac** with Xcode for builds, signing, and App Store upload.

Current app version (from `pubspec.yaml`): **1.0.5 (6)** — use **1.0.5** / build **6** for the first iOS release unless you bump it.

---

## Phase 1 — Apple Developer & App Store Connect

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. Open [App Store Connect](https://appstoreconnect.apple.com/) → **Apps** → **+** → **New App**.
   - **Platform:** iOS  
   - **Name:** Babyland  
   - **Primary language:** English  
   - **Bundle ID:** `com.thebabyland` (create under [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if missing)  
   - **SKU:** e.g. `babyland-ios-001`
3. Fill **App Privacy**, **Support URL**, and **Privacy Policy URL** (same URLs as Play Store if possible).

---

## Phase 2 — Firebase (same project as Android)

Project: **`thebabyland-6db6d`**

1. [Firebase Console](https://console.firebase.google.com/) → **thebabyland-6db6d** → **Add app** → **iOS**.
2. **Bundle ID:** `com.thebabyland`
3. Download **`GoogleService-Info.plist`** → place at:
   ```
   ios/Runner/GoogleService-Info.plist
   ```
4. On your Mac, regenerate Dart options (fixes `appId` / API keys):
   ```bash
   dart pub global activate flutterfire_cli
   cd /path/to/babyland
   flutterfire configure --project=thebabyland-6db6d --platforms=ios,android
   ```
5. **Authentication → Sign-in method:** enable **Phone**, **Google**, and **Apple** (same as Android).
6. **Project settings → Cloud Messaging → Apple app configuration:** upload your **APNs Authentication Key** (.p8 from Apple Developer → Keys). Required for **push notifications** and **Firebase Phone OTP** on iOS.

### Google Sign-In URL scheme

After `GoogleService-Info.plist` is in place, open it and copy **`REVERSED_CLIENT_ID`**.  
Add a second entry under **`CFBundleURLTypes`** in `ios/Runner/Info.plist`:

```xml
<dict>
  <key>CFBundleTypeRole</key>
  <string>Editor</string>
  <key>CFBundleURLSchemes</key>
  <array>
    <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
  </array>
</dict>
```

(Use the exact `REVERSED_CLIENT_ID` value from the plist.)

---

## Phase 3 — Xcode signing (on Mac)

1. Open **`ios/Runner.xcworkspace`** (not `.xcodeproj`).
2. Select **Runner** target → **Signing & Capabilities**.
3. Set **Team** to your Apple Developer team (automatic signing).
4. Confirm capabilities are present (entitlements file already added):
   - **Push Notifications**
   - **Sign in with Apple**
5. **Product → Archive** to verify signing works.

`ios/Runner/Runner.entitlements` already includes Apple Sign-In and push (`aps-environment` = production).

---

## Phase 4 — App icons

App Store requires a **1024×1024** PNG (no transparency).  
Add all sizes under:

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Tip: use [appicon.co](https://www.appicon.co/) or Xcode’s asset catalog after dropping in the 1024×1024 master icon.

---

## Phase 5 — Build & TestFlight

On Mac, from the repo root:

```bash
chmod +x tools/build_ios_release.sh
./tools/build_ios_release.sh
```

Or manually:

```bash
cd ios && pod install && cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Upload the `.ipa` from `build/ios/ipa/` using **Transporter** or Xcode **Organizer → Distribute App**.

Add internal testers in App Store Connect → **TestFlight**, then test:

- Phone OTP login  
- Google Sign-In  
- Sign in with Apple  
- Push notifications  
- Doctor video call (Agora)  
- Consultation payment return deep link (`babyland://consultation-payment-return`)

---

## Phase 6 — App Store submission

1. Complete **App Store** tab: description, keywords, screenshots (6.7", 6.5", 5.5" iPhone sizes).
2. **App Review Information:** demo account if login is required.
3. **Export compliance:** typically “No” for standard HTTPS/TLS (confirm in questionnaire).
4. Answer **Foreground Services** / permissions questionnaires honestly (camera, mic, notifications — no screen recording).
5. Submit for review.

---

## Already configured in this repo

| Item | Status |
|------|--------|
| Bundle ID `com.thebabyland` | Done in Xcode project |
| Podfile + permission_handler macros | Done |
| Privacy usage strings (camera, mic, speech, photos, Bluetooth) | Done in Info.plist |
| Push background mode + AppDelegate APNs registration | Done |
| Sign in with Apple entitlements | Done |
| Payment deep link scheme `babyland` | Done |
| Firebase options aligned to `thebabyland-6db6d` | Done — synced with `GoogleService-Info.plist` |
| Google Sign-In URL scheme (`REVERSED_CLIENT_ID`) | Done in Info.plist |
| `GoogleService-Info.plist` in Xcode project | Done |
| iOS App Check support in Dart | Done (disabled by default, same as Android) |
| Release build script | `tools/build_ios_release.sh` |
| Codemagic cloud CI | `codemagic.yaml` (TestFlight upload) |

---

## Important notes

- **Windows cannot build iOS.** Prepare config here; build on Mac or CI (Codemagic, GitHub Actions + Mac runner, etc.).
- **PhonePe / UPI** may not work for all iOS users — confirm payment strategy for Apple reviewers.
- **HTTP API** (`http://164.52.197.176`) is allowed via ATS for now; Apple may ask for HTTPS long term.
- **`GoogleService-Info.plist`** is present at `ios/Runner/GoogleService-Info.plist` and wired into the Xcode project.

---

## No Mac? Use Codemagic (recommended)

A **`codemagic.yaml`** is in the repo root. Codemagic builds on a cloud Mac and uploads to **TestFlight** for you.

### Step A — App Store Connect (web, ~15 min)

1. Go to [App Store Connect](https://appstoreconnect.apple.com/) → **Apps** → **+** → **New App**.
   - Name: **Babyland**
   - Bundle ID: **`com.thebabyland`** (create under [Identifiers](https://developer.apple.com/account/resources/identifiers/list) if it does not exist)
   - SKU: `babyland-ios-001`
2. Create an **App Store Connect API key**:
   - App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **+**
   - Role: **App Manager** (or Admin)
   - Download the **.p8** file — you can only download it once
   - Note the **Issuer ID** and **Key ID**

### Step B — Firebase APNs (web, ~10 min)

1. [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) → **Keys** → **+** → enable **Apple Push Notifications service (APNs)** → download **.p8**
2. [Firebase Console](https://console.firebase.google.com/) → **thebabyland-6db6d** → ⚙️ **Project settings** → **Cloud Messaging** → **Apple app configuration**
3. Upload the APNs key (Key ID + Team ID + .p8 file)

Without this, **push notifications** and **phone OTP on iOS** may fail.

### Step C — Codemagic (web, ~20 min)

1. Sign up at [codemagic.io](https://codemagic.io) → **Add application** → connect your Git repo (GitHub / GitLab / Bitbucket).
2. **Team settings** → **Integrations**:
   - **Apple Developer Portal** → connect with your Apple ID (Codemagic manages certs/profiles)
   - **App Store Connect** → add API key (Issuer ID, Key ID, upload .p8)
3. In your app on Codemagic → **Start new build** → workflow **`ios-testflight-manual`** (first time; no branch trigger needed).
4. When the build succeeds, open **TestFlight** in App Store Connect → install on your iPhone.

### Step D — App icon (required before App Store review)

Add a **1024×1024 PNG** to `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and commit. TestFlight may work without it; **App Store submission will not**.

### Step E — After TestFlight testing

In App Store Connect → your app → **App Store** tab → add screenshots, description, privacy policy URL → **Submit for Review**.

---

## Quick checklist

- [x] Apple Developer account active  
- [ ] App Store Connect app created (`com.thebabyland`)  
- [x] Firebase iOS app + `GoogleService-Info.plist`  
- [x] `firebase_options.dart` synced with plist  
- [x] Google `REVERSED_CLIENT_ID` added to Info.plist  
- [ ] APNs key uploaded to Firebase  
- [ ] App icons (1024×1024 + asset catalog)  
- [ ] Codemagic connected + first TestFlight build succeeds  
- [ ] TestFlight tested on real iPhone  
- [ ] App Store metadata + submit  
