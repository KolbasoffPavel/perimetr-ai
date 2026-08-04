import java.util.Properties
import java.io.FileInputStream

plugins {
id("com.android.application")
id("kotlin-android")
id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
namespace = "com.perimetr.perimetr_native"
compileSdk = flutter.compileSdkVersion
ndkVersion = flutter.ndkVersion

compileOptions {
sourceCompatibility = JavaVersion.VERSION_17
targetCompatibility = JavaVersion.VERSION_17
}

defaultConfig {
applicationId = "com.perimetr.perimetr_native"
minSdk = flutter.minSdkVersion
targetSdk = flutter.targetSdkVersion
versionCode = flutter.versionCode
versionName = flutter.versionName
}

signingConfigs {
create("release") {
if (hasKeystore) {
keyAlias = keystoreProperties["keyAlias"] as String
keyPassword = keystoreProperties["keyPassword"] as String
storeFile = file(keystoreProperties["storeFile"] as String)
storePassword = keystoreProperties["storePassword"] as String
}
}
}

buildTypes {
release {
signingConfig = if (hasKeystore) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
isMinifyEnabled = true
isShrinkResources = true
proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
}
}
}

flutter {
source = "../.."
}
