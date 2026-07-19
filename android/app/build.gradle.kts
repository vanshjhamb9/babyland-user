import com.flutter.gradle.tasks.FlutterTask
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.thebabyland"
    compileSdk = flutter.compileSdkVersion
    // Side-by-side NDK from Android Studio SDK Manager (matches newest installed: 30.x).
    ndkVersion = "30.0.14904198"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

    // kotlinOptions {
    //     jvmTarget = JavaVersion.VERSION_11.toString()
    // }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.thebabyland"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // arm64-only APK: ~3x less AOT work than arm+arm64+x64 on 7GB Windows hosts.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // Play Console requires release signing (not debug). Set up:
            //   .\tools\setup_release_keystore.ps1
            // Then register SHA-1 + SHA-256 in Firebase and rebuild google-services.json.
            val requireReleaseSigning = project.hasProperty("requireReleaseSigning")
            val allowDebugReleaseSigning =
                project.findProperty("allowDebugReleaseSigning")?.toString() == "true"
            signingConfig = when {
                keystorePropertiesFile.exists() -> signingConfigs.getByName("release")
                requireReleaseSigning -> error(
                    "Play Store build requires android/key.properties. " +
                        "Run: .\\tools\\setup_release_keystore.ps1",
                )
                allowDebugReleaseSigning -> {
                    logger.warn(
                        "android/key.properties missing — release builds use DEBUG signing. " +
                            "Run .\\tools\\setup_release_keystore.ps1 before Play Console upload.",
                    )
                    signingConfigs.getByName("debug")
                }
                else -> error(
                    "android/key.properties missing. Run .\\tools\\setup_release_keystore.ps1 " +
                        "or set allowDebugReleaseSigning=true in gradle.properties for local testing only.",
                )
            }
            // 8GB RAM / -Xmx1024m: R8 minify OOMs on Firebase+Agora stack. Re-enable on CI with shrink=true.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    buildFeatures {
        buildConfig = true
    }

    packaging {
        jniLibs {
            // Fewer surprises when extracting native libs on older devices; also avoids some packaging edge cases.
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

// Belt-and-suspenders: ensure Agora screen modules never reach the release manifest.
configurations.configureEach {
    exclude(group = "io.agora.rtc", module = "full-screen-sharing")
    exclude(group = "io.agora.rtc", module = "screen-capture")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Phone Auth: Play Integrity + reCAPTCHA fallback on release/sideloaded APKs.
    implementation("com.google.android.play:integrity:1.4.0")
    implementation("com.google.android.gms:play-services-auth:21.3.0")
    // reCAPTCHA fallback opens in Chrome Custom Tabs (Android 11+ needs manifest <queries> too).
    implementation("androidx.browser:browser:1.8.0")
    implementation("com.google.android.recaptcha:recaptcha:18.6.1")
}

// Permanent low-RAM release settings (Flutter CLI -P flags cannot override task fields here).
afterEvaluate {
    tasks.withType<FlutterTask>().configureEach {
        treeShakeIcons = false
        targetPlatformValues = listOf("android-arm64")
    }

    // #region agent log
    val release = android.buildTypes.getByName("release")
    val minifyTask = tasks.findByName("minifyReleaseWithR8")
    val logFile = rootProject.layout.projectDirectory.file("../debug-64f774.log").asFile
    val runId = System.getenv("DEBUG_RUN_ID") ?: "pre-fix"
    val dataJson =
        """"minifyEnabled":${release.isMinifyEnabled},"shrinkResources":${release.isShrinkResources},"minifyTaskExists":${minifyTask != null},"minifyTaskEnabled":${minifyTask?.enabled ?: false}"""
    logFile.appendText(
        """{"sessionId":"64f774","runId":"$runId","hypothesisId":"H5","location":"app/build.gradle.kts:afterEvaluate","message":"release shrink settings","data":{$dataJson},"timestamp":${System.currentTimeMillis()}}""" +
            "\n",
    )
    if (minifyTask != null && release.isMinifyEnabled.not()) {
        minifyTask.enabled = false
    }
    tasks.matching { it.name == "assembleRelease" }.configureEach {
        doLast {
            val apkDir = layout.buildDirectory.dir("outputs/flutter-apk").get().asFile
            val apks = apkDir.listFiles()?.filter { it.extension == "apk" }?.map { it.name } ?: emptyList()
            logFile.appendText(
                """{"sessionId":"64f774","runId":"$runId","hypothesisId":"H6","location":"app/build.gradle.kts:assembleRelease.doLast","message":"assembleRelease completed","data":{"apkDir":"${apkDir.absolutePath}","apks":"${apks.joinToString(",")}"},"timestamp":${System.currentTimeMillis()}}""" +
                    "\n",
            )
        }
    }
    // #endregion
}

// Windows / AGP: avoid FileNotFoundException for dex-renamer-state.txt during
// PackageAndroidArtifact$IncrementalSplitterRunnable (missing tmp dirs).
afterEvaluate {
    tasks.matching { it.name == "packageDebug" }.configureEach {
        doFirst {
            val dir =
                layout.buildDirectory
                    .dir("intermediates/incremental/packageDebug/tmp/debug")
                    .get()
                    .asFile
            if (!dir.exists() && !dir.mkdirs()) {
                logger.warn("Could not mkdir ${dir.absolutePath}")
            }
        }
    }
}
