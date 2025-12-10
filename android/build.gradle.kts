// build.gradle.kts
plugins {
    id("com.android.application") version "8.4.1" apply false
    id("com.android.library") version "8.4.1" apply false

    // CHANGE THIS LINE: 1.9.22 -> 2.0.0
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false

    id("com.google.gms.google-services") version "4.4.0" apply false
    id("com.google.dagger.hilt.android") version "2.48" apply false

    // CHANGE THIS LINE: 1.9.22 -> 2.0.0
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.22" apply false
}