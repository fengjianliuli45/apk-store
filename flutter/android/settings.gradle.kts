pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

val unityLibraryDirectory = file("unityLibrary")
if (unityLibraryDirectory.resolve("build.gradle").exists()) {
    val unityExportPropertiesFile = file("unity-export.properties")
    require(unityExportPropertiesFile.exists()) {
        "unity-export.properties is missing; rerun tools/sync_unity_android_library.ps1"
    }
    val unityExportProperties = java.util.Properties().apply {
        unityExportPropertiesFile.inputStream().use { load(it) }
    }
    gradle.beforeProject {
        unityExportProperties.forEach { key, value ->
            val propertyName = key.toString()
            if (!extensions.extraProperties.has(propertyName)) {
                extensions.extraProperties.set(propertyName, value)
            }
        }
        if (
            !hasProperty("target-platform") &&
            unityExportProperties.getProperty("unity.abiFilters") == "arm64-v8a"
        ) {
            extensions.extraProperties.set("target-platform", "android-arm64")
        }
    }
    include(":unityLibrary")
    project(":unityLibrary").projectDir = unityLibraryDirectory
}
