plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.centim"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.centim"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define signing configs
    signingConfigs {
        create("release") {
            val keystoreFile = rootProject.file("key.properties")
            if (keystoreFile.exists()) {
                val properties = java.util.Properties()
                properties.load(java.io.FileInputStream(keystoreFile))

                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
            } else {
                // Fallback to debug signing if key.properties is missing
                // This ensures local builds work without setup, but CI works with secrets
                val debugKeystore = rootProject.file("app/debug.keystore")
                 if (debugKeystore.exists()) {
                    storeFile = debugKeystore
                 } else {
                    storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
                 }
                 storePassword = "android"
                 keyAlias = "androiddebugkey"
                 keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            // Apply the release signing config
            // Note: If key.properties is missing, this might fail if we don't set it up correctly in the "else" above.
            // A safer approach for Mixed environment:
            val keystoreFile = rootProject.file("key.properties")
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
