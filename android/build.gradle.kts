allprojects {
repositories {
google()
mavenCentral()
}
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
project.evaluationDependsOn(":app")
}

// opencv_dart (используется flutter_panorama) объявляет внутри себя
// устаревший compileSdk=33, который конфликтует с более новыми
// зависимостями (androidx.fragment, androidx.exifinterface и т.п.,
// требующими compileSdk 34+). Поднимаем compileSdk ТОЛЬКО для этого
// конкретного модуля — трогать остальные подмодули/плагины не нужно и
// местами даже опасно (некоторые из них, например ar_flutter_plugin_plus,
// фиксируют свой compileSdk раньше, чем можно его переопределить, и падают
// с ошибкой "too late to set compileSdk" при попытке).
subprojects {
if (project.name == "opencv_dart") {
plugins.withId("com.android.library") {
val ext = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
if (project.state.executed) {
ext.compileSdkVersion(36)
} else {
afterEvaluate { ext.compileSdkVersion(36) }
}
}
}
}

tasks.register<Delete>("clean") {
delete(rootProject.layout.buildDirectory)
}
