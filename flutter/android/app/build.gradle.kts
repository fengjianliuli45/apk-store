plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val unityLibraryIncluded = rootProject.findProject(":unityLibrary") != null

android {
    namespace = "com.restpod.hud"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.restpod.hud"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = if (unityLibraryIncluded) 26 else flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        if (unityLibraryIncluded) {
            ndk {
                // Unity export is arm64-only, while Android Studio's test
                // emulator is x86_64. Keep both ABIs in debug/universal APKs:
                // Flutter can run on the emulator and Unity remains available
                // on arm64 phones.
                abiFilters += listOf("arm64-v8a", "x86_64")
            }
        }
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    if (unityLibraryIncluded) {
        sourceSets.getByName("main").manifest.srcFile("src/unity/AndroidManifest.xml")
        sourceSets.getByName("main").java.srcDir("src/unity/kotlin")
        packaging {
            jniLibs {
                useLegacyPackaging = true
                excludes += setOf(
                    "**/armeabi-v7a/*.so",
                    "**/x86/*.so",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    if (unityLibraryIncluded) {
        implementation(project(":unityLibrary"))
        implementation("com.google.android.play:asset-delivery:2.3.0")
        // UnityPlayerActivity exposes public supertypes from this jar, while
        // unityLibrary intentionally keeps its fileTree dependency internal.
        compileOnly(files(rootProject.file("unityLibrary/libs/unity-classes.jar")))
    }
}
