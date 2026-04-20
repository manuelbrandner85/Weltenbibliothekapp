// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔐 Release-Keystore laden (persistenter Key für APK-Over-the-Top-Updates).
// Quelle: android/key.properties → wird in CI aus GitHub-Secrets erzeugt.
// Ohne key.properties (lokale Dev-Umgebung) bleibt der Release-Build debug-signiert.
val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) {
        load(FileInputStream(keystorePropsFile))
    }
}
val hasReleaseKeystore = keystoreProps.getProperty("storeFile")?.isNotBlank() == true

android {
    namespace = "com.myapp.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ FIX: Core library desugaring für flutter_local_notifications
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    // ✅ FIX: Disable Lint for faster builds
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    defaultConfig {
        applicationId = "com.myapp.mobile"
        // Android 5.0+ (API 21) – deckt >99% aller aktiven Android-Geräte ab
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ARM64 (moderne Geräte) + ARM32 (ältere/32-bit Geräte)
        // x86_64 wird weggelassen – Shorebird unterstützt es nicht im Prod-Release
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    signingConfigs {
        // 🔐 Persistenter Release-Key (nur wenn key.properties vorhanden).
        // Damit sind alle zukünftigen APKs mit dem gleichen Key signiert →
        // User können Updates ohne Deinstallation installieren.
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback: Debug-Key (nur Dev / lokaler `flutter run --release`).
                // CI setzt IMMER key.properties aus den Secrets.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true // Enable code shrinking
            isShrinkResources = true // Enable resource shrinking
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// ✅ FIX: Core library desugaring dependency
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}



