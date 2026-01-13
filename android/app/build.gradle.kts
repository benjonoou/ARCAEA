plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = 36  // Health Connect 需要 API 36 (Android 15)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29  // Samsung Health SDK 需要 API 29+
        targetSdk = 34  // Health Connect 需要 API 34 (Android 14)
        versionCode = 3  // 明確設定版本號，讓 Health Connect 識別為新版本
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Samsung Health SDK - 類別無法解析，已註解
    // implementation(files("libs/samsung-health-data-api-1.0.0.aar"))
    
    // Health Connect 客戶端庫 - 使用最新穩定版
    implementation("androidx.health.connect:connect-client:1.1.0")
}
