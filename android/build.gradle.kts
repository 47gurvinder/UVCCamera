plugins {
    id("com.android.library")
}

version = run {
    val pubspecContent = file("../pubspec.yaml").readText()
    val pubspecVersionMatch = Regex("version:\\s+(.*)").find(pubspecContent)
    val pubspecVersion = pubspecVersionMatch?.groupValues?.get(1)
    pubspecVersion ?: "0.0.0-SNAPSHOT"
}

android {
    namespace = "org.uvccamera.flutter"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("org.uvccamera:lib:0.0.9") // NOTE: Use org.uvccamera:lib of the same version as the plugin.
    implementation("io.agora.rtc:agora-special-full:4.5.0.1")
//    implementation("io.agora.rtc:full-sdk:4.5.1")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
