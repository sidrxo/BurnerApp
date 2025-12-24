plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.dagger.hilt.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("kotlin-kapt") // Needed for Hilt
}

android {
    namespace = "com.gas.Burner" // Replace with your actual package name
    compileSdk = 34 // This was the missing line!

    defaultConfig {
        applicationId = "com.your.package.burner"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
}

dependencies {
    // This fixes the "no com.google.dagger:hilt-android dependency was found" error
    implementation("com.google.dagger:hilt-android:2.51.1")
    kapt("com.google.dagger:hilt-android-compiler:2.51.1")
}