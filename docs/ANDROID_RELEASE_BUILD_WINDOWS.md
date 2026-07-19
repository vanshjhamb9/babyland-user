# Android release build on Windows

## NDK 27 vs 28 warning

You may see:

> `speech_to_text requires Android NDK 28.2.13676358`

The app is pinned to **NDK 27** because **NDK 28** often fails on Windows with CMake errors (`crtbegin_dynamic.o` not found, `-lm` / `-lc` missing). That message is a **compatibility warning**; the build can still succeed with NDK 27.

## Icon tree shaker / Dart VM crash

**Symptom:** `IconTreeShakerException`, `ConstFinder failure`, or `Could not start thread dart:io EventHandler` during `compileFlutterBuildRelease`.

**Fix (permanent in repo):** icon tree-shaking is disabled in `gradle.properties` and `app/build.gradle.kts`. Do not pass `--tree-shake-icons`; use `--no-tree-shake-icons` only if you override locally.

## `mergeReleaseResources` — Unable to delete directory

**Symptom:** `Execution failed for task ':sqflite_android:mergeReleaseResources'` with *Failed to delete some children* / *New files were found* under `build\sqflite_android\intermediates\...`.

**Cause:** On Windows, redirecting **every** Android plugin into the shared repo `build/<plugin>/` folder makes incremental resource merges fight over the same directories (file locks + cleanup races). Builds that run for hours (low RAM / swap) make this worse.

**Permanent fix in repo:**

- `android/build.gradle.kts` — only `:app` uses `<repo>/build/app`; plugins use their default `{projectDir}/build`.
- All `MergeResources` tasks run with `incremental = false` (non-incremental merge, stable on Windows).
- Pre-deletes stale `merge*Resources` incremental folders before each merge task (Windows file-lock workaround).

**Build:**

```powershell
.\tools\build_apk_release.ps1
```

Quick check (minutes, not hours) after a failed build:

```powershell
.\tools\build_apk_release.ps1 -QuickMergeTest
```

## AAPT2 `verifyReleaseResources` daemon error

**Symptom:** `:sqflite_android:verifyReleaseResources` — `AAPT2 ... Unexpected error during link, attempting to stop daemon`.

**Fix in repo:** `android.enableAapt2Daemon=false` in `gradle.properties` (runs one-shot AAPT2 instead of a persistent daemon; slower but stable on 8GB Windows).

## Lint `Metaspace` / `:firebase_analytics:lintVitalAnalyzeRelease`

**Symptom:** `Execution failed for task ':firebase_analytics:lintVitalAnalyzeRelease'` with `OutOfMemoryError: Metaspace` during lint analysis.

**Fix in repo:** `android.lint.checkReleaseBuilds=false` in `gradle.properties`, plus all `lintVital*` tasks disabled in `android/build.gradle.kts`. Release APK builds skip vital lint on this machine; run lint on CI or Android Studio when needed.

## R8 `OutOfMemoryError: Java heap space` (`:app:minifyReleaseWithR8`)

**Symptom:** `ERROR: R8: java.lang.OutOfMemoryError: Java heap space` after 20–40+ minutes of building.

**Cause:** Flutter enables **code shrinking** by default (`shrink=true`). R8 needs far more than the `1024m` Gradle heap used on 8GB Windows machines (this app has Firebase, Agora, WebView, etc.).

**Permanent fix in repo:**

- `android/gradle.properties` → `shrink=false`
- `android/app/build.gradle.kts` → `isMinifyEnabled = false`, `isShrinkResources = false` on `release`

APK will be **larger** but builds reliably. For Play Store on a 16GB+ machine or CI, set `shrink=true` and raise `-Xmx` in `gradle.properties`.

## Gradle daemon disappeared / `hs_err_pid*.log`

**Symptom:** `Gradle build daemon disappeared unexpectedly` and a file like `android/hs_err_pid40908.log` with:

> There is insufficient memory for the Java Runtime Environment to continue.

That is a **native memory** crash (not always the Java heap). Typical on **8GB RAM** laptops with a small Windows page file, especially when building a **universal** release APK (all ABIs in one package).

**Already applied in the project:**

- `android/gradle.properties` — modest Gradle heap (`-Xmx1024m`), smaller stacks, capped metaspace/code cache, `-XX:HeapBaseMinAddress=2g`, `-XX:CICompilerCount=2`, in-process Kotlin, `tree-shake-icons=false`, `target-platform=android-arm64`
- `android/app/build.gradle.kts` — **arm64-only** APK (`abiFilters`), disables icon tree-shaking and multi-ABI AOT on all `FlutterTask`s (survives `flutter build apk --release` without extra flags)
- `app_links` ^7.0.0 — fixes AGP 8.11 `compileSdk` / `flutter` property errors

### Gradle lock / `buildLogic.lock` timeout

**Symptom:** `Timeout waiting to lock build logic queue` — Owner PID is often the **Cursor/VS Code Java** extension, not your terminal build.

**Fix:** `.vscode/settings.json` disables automatic Gradle import for Java. **Reload the Cursor window** once, then run the build script. Do not start a second `flutter build` while one is running.

### Recommended build command

From the repo root (same flags as Gradle; stops daemons first):

```powershell
.\tools\build_apk_release.ps1
```

Optional: `-SplitPerAbi` if you later remove the arm64-only pin and want one APK per architecture.

Plain Flutter also works:

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk` (arm64 devices; most phones since ~2017).

### If it still crashes

1. **Free RAM** — close browsers, Android Studio emulators, and other Gradle/Java processes.
2. **Windows page file** — Settings → System → About → Advanced system settings → Performance → Advanced → Virtual memory. Set a **managed** page file on the system drive (often helps when physical RAM is 8GB).
3. **Retry per-ABI** — always use `--split-per-abi` on low-RAM machines.
4. **Do not raise `-Xmx`** above `1024m` on 8GB machines; a larger Java heap can **worsen** native OOM (see comments in `hs_err_pid*.log`).

Crash logs (`hs_err_pid*.log`, `replay_pid*.log`) are gitignored; safe to delete after fixing.

## Optional: repair NDK 28 (only if you must use it)

1. Android Studio → SDK Manager → SDK Tools → **NDK (Side by side)** → uninstall **28.2.13676358**, then install it again.
2. Install a newer **CMake** (e.g. 3.31.x) via SDK Tools.
3. In `android/app/build.gradle.kts` set `ndkVersion = "28.2.13676358"` and rebuild.

If CMake still fails, stay on NDK 27 as above.
