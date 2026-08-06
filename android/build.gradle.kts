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

// Некоторые сторонние плагины (например, opencv_dart, используемый
// flutter_panorama) объявляют внутри себя устаревший compileSdk, который
// конфликтует с более новыми зависимостями (androidx.fragment,
// androidx.exifinterface и т.п., требующими compileSdk 34+). Мы не можем
// поправить это внутри самого плагина (он приходит из pub cache), поэтому
// принудительно поднимаем compileSdk для ВСЕХ подмодулей проекта, включая
// плагины, до 36. Используем plugins.withId вместо afterEvaluate — он
// срабатывает сразу при применении Android-плагина к модулю, независимо
// от порядка evaluation (в отличие от afterEvaluate, который может
// сработать слишком поздно в новой архитектуре Gradle-загрузки Flutter).
subprojects {
plugins.withId("com.android.library") {
extensions.configure<com.android.build.gradle.LibraryExtension> {
compileSdk = 36
}
}
plugins.withId("com.android.application") {
extensions.configure<com.android.build.gradle.AppExtension> {
compileSdk = 36
}
}
}

tasks.register<Delete>("clean") {
delete(rootProject.layout.buildDirectory)
}
