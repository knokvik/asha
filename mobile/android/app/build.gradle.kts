plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.nhm.asha.asha_platform"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nhm.asha.asha_platform"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
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

configurations.all {
    // Force updated androidx libraries so all plugins pass AAR metadata check at compileSdk 37
    resolutionStrategy.force(
        "androidx.fragment:fragment:1.8.6",
        "androidx.window:window:1.4.0",
        "androidx.window:window-java:1.4.0",
        "androidx.activity:activity:1.10.1",
        "androidx.lifecycle:lifecycle-livedata-core-ktx:2.9.0",
        "androidx.lifecycle:lifecycle-livedata:2.9.0",
        "androidx.lifecycle:lifecycle-viewmodel:2.9.0",
        "androidx.lifecycle:lifecycle-livedata-core:2.9.0",
        "androidx.lifecycle:lifecycle-viewmodel-savedstate:2.9.0",
        "androidx.lifecycle:lifecycle-runtime:2.9.0",
        "androidx.lifecycle:lifecycle-process:2.9.0",
        "androidx.core:core:1.16.0",
        "androidx.core:core-ktx:1.16.0",
        "androidx.annotation:annotation-experimental:1.4.1",
        "androidx.exifinterface:exifinterface:1.4.1"
    )
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
