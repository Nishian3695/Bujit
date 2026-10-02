import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, as in the Java app: the same keystore, so Play accepts this app
// as an update to it. Locally: copy android/keystore.properties.example to
// android/keystore.properties (never committed) and fill it in. In CI, the
// STORE_FILE / STORE_PASSWORD / KEY_ALIAS / KEY_PASSWORD environment variables win.
// Without either, release builds come out unsigned (they still compile).
val keystoreProps = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(env: String, key: String): String? =
    (System.getenv(env) ?: keystoreProps.getProperty(key))?.trim()?.removeSurrounding("\"")
val storeFilePath = signingValue("STORE_FILE", "storeFile")

android {
    namespace = "io.github.nishian3695.bujit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.nishian3695.bujit"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml's version (name+code); see the note there.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!storeFilePath.isNullOrEmpty()) {
            create("release") {
                storeFile = file(storeFilePath)
                storePassword = signingValue("STORE_PASSWORD", "storePassword")
                keyAlias = signingValue("KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

dependencies {
    // Release App Check: Play Integrity's Standard API, exchanged at the backend for an
    // App Check token (see StandardIntegrityAppCheckProvider in src/release).
    releaseImplementation("com.google.android.play:integrity:1.6.0")
    releaseImplementation(platform("com.google.firebase:firebase-bom:34.19.0"))
    releaseImplementation("com.google.firebase:firebase-appcheck")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
