
import java.util.Properties

plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    id("kotlin-android")

    // Flutter Gradle Plugin phải đặt sau Android và Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Đọc Google Maps API key từ android/local.properties.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")

if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use {
        localProperties.load(it)
    }
}

val mapsApiKey = localProperties.getProperty(
    "MAPS_API_KEY",
    ""
)

android {
    namespace = "com.joblink.joblink_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.joblink.joblink_mobile"

        // Google Maps Flutter phiên bản hiện tại yêu cầu Android SDK 24+.
        minSdk = maxOf(flutter.minSdkVersion, 24)

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // Cấu hình ký release hiện tại của dự án.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
