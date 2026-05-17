import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─── Read signing config from key.properties (kept OUT of git via .gitignore) ───
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "studio.xman.pos_thaiprompt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for ota_update plugin (uses java.time / NIO APIs from Java 8+
        // that need backporting on older Android API levels).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Stable Application ID — must NEVER change between releases or
        // Android won't recognize new APK as an update of the existing one.
        // Same signing key + same applicationId = APK overwrites cleanly.
        applicationId = "studio.xman.pos_thaiprompt"
        minSdk = 24                              // Android 7.0 (covers ~98% of devices)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Used by GitHub Actions (decoded from base64 secret) AND local release builds.
            // Provide values via key.properties or environment (CI export RELEASE_KEYSTORE_*).
            keyAlias       = keystoreProperties.getProperty("keyAlias")    ?: System.getenv("RELEASE_KEY_ALIAS")
            keyPassword    = keystoreProperties.getProperty("keyPassword") ?: System.getenv("RELEASE_KEY_PASSWORD")
            storeFile      = (keystoreProperties.getProperty("storeFile") ?: System.getenv("RELEASE_KEYSTORE_PATH"))?.let { file(it) }
            storePassword  = keystoreProperties.getProperty("storePassword") ?: System.getenv("RELEASE_STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            // Use release signing if config is present, else fall back to debug
            // (so `flutter run --release` works locally without a keystore).
            signingConfig = if (signingConfigs.getByName("release").storeFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backport modern Java APIs to older Android — required by ota_update.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
