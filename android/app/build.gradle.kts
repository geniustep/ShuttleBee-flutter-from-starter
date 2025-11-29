plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bridgecore_flutter_starter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.example.bridgecore_flutter_starter"

        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // دعم Java 11 + desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // 👇 مهم لحل الخطأ مع flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    // Disable Kotlin incremental compilation to avoid cache issues on Windows
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            incremental = false
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // يمكنك تفعيل التصغير إذا أردت لاحقًا
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // إعدادات debug الافتراضية
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // (اختياري) أحيانًا مفيد لتفادي تعارض بعض الملفات في مكتبات مختلفة
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 👇 مكتبة desugaring المطلوبة
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
