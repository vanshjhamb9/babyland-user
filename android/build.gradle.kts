import com.android.build.gradle.tasks.MergeResources
import java.io.File

plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Video calls only — strip Agora screen capture/sharing (adds FOREGROUND_SERVICE_MEDIA_PROJECTION).
    configurations.configureEach {
        exclude(group = "io.agora.rtc", module = "full-screen-sharing")
        exclude(group = "io.agora.rtc", module = "screen-capture")
    }
}

// Flutter expects the app APK under `<repo>/build/app/outputs/flutter-apk/`.
// Only :app uses that tree. Plugin modules keep the default `{projectDir}/build`
// so Windows does not race on shared `build/<plugin>/intermediates/...` deletes.
val flutterBuildRoot = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(flutterBuildRoot)

subprojects {
    if (name == "app") {
        layout.buildDirectory.set(flutterBuildRoot.dir("app"))
    }
}

// #region agent log
fun agentDebugLog(
    hypothesisId: String,
    location: String,
    message: String,
    data: Map<String, Any?>,
) {
    val logFile = rootProject.layout.projectDirectory.file("../debug-64f774.log").asFile
    val runId = System.getenv("DEBUG_RUN_ID") ?: "pre-fix"
    val dataJson =
        data.entries.joinToString(",") { (k, v) ->
            "\"$k\":${if (v is Number || v is Boolean) v else "\"${v.toString().replace("\"", "'")}\""}"
        }
    logFile.appendText(
        """{"sessionId":"64f774","runId":"$runId","hypothesisId":"$hypothesisId","location":"$location","message":"$message","data":{$dataJson},"timestamp":${System.currentTimeMillis()}}""" +
            "\n",
    )
}
// #endregion

// Windows / 8GB RAM: lintVitalAnalyzeRelease Metaspace OOM (firebase_analytics, etc.).
subprojects {
    afterEvaluate {
        tasks.matching { it.name.startsWith("lintVital") }.configureEach {
            enabled = false
            // #region agent log
            agentDebugLog(
                "H7",
                "build.gradle.kts:lintVital",
                "disabled lintVital task",
                mapOf("project" to project.name, "task" to name),
            )
            // #endregion
        }
    }
}

// Windows: "Unable to delete directory ... mergeReleaseResources" — incremental cleanup races.
subprojects {
    afterEvaluate {
        tasks.withType<MergeResources>().configureEach {
            outputs.upToDateWhen { false }
            // #region agent log
            doFirst {
                val variant = if (name.contains("Debug", ignoreCase = true)) "debug" else "release"
                val mergeDir =
                    layout.buildDirectory
                        .dir("intermediates/incremental/$variant/$name")
                        .get()
                        .asFile
                val existedBefore = mergeDir.exists()
                val childCountBefore =
                    if (existedBefore) mergeDir.listFiles()?.size ?: 0 else 0
                if (existedBefore) {
                    project.delete(mergeDir)
                }
                agentDebugLog(
                    "H1",
                    "build.gradle.kts:MergeResources.doFirst",
                    "pre-deleted merge incremental dir",
                    mapOf(
                        "project" to project.name,
                        "task" to name,
                        "buildDir" to layout.buildDirectory.get().asFile.absolutePath,
                        "existedBefore" to existedBefore,
                        "childCountBefore" to childCountBefore,
                        "existsAfterPreDelete" to mergeDir.exists(),
                    ),
                )
            }
            doLast {
                agentDebugLog(
                    "H3",
                    "build.gradle.kts:MergeResources.doLast",
                    "mergeResources finished",
                    mapOf("project" to project.name, "task" to name),
                )
            }
            // #endregion
        }
    }
}

// Ensure :app is configured before plugin projects so the Flutter Gradle plugin
// can register pluginProject.afterEvaluate (Gradle 8+ disallows afterEvaluate
// on projects that are already evaluated).
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
