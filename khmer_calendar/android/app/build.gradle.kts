plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Dev build (CI sets KHMER_DEV=true): installs side by side with the production app.
val isDev = System.getenv("KHMER_DEV") == "true"

android {
    namespace = "com.mounsokdara.khmercalendar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mounsokdara.khmercalendar"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = if (isDev) "ប្រតិទិនខ្មែរ Dev" else "ប្រតិទិនខ្មែរ"
        if (isDev) {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
    }

    packaging {
        jniLibs {
            // Keep native libraries compressed inside the APK (about half the size).
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("release") {
            // Credentials come from environment variables (GitHub Actions secrets or local shell). Never hardcode.
            val ks = System.getenv("ANDROID_KEYSTORE")
            if (ks != null && file(ks).exists()) {
                storeFile = file(ks)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: "com.mounsokdara.khmercalendar"
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val rel = signingConfigs.findByName("release")
            signingConfig = if (rel?.storeFile?.exists() == true) rel else throw GradleException("Release keystore missing: refusing to sign a release build with the debug key")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.startup:startup-runtime:1.2.0")
}
