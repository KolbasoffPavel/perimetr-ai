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
// плагины, до 36. plugins.withId срабатывает сразу при применении
// Android-плагина, независимо от порядка evaluation.
subprojects {
plugins.withId("com.android.library") {
extensions.getByType(com.android.build.gradle.LibraryExtension::class.java).compileSdkVersion(36)
}
plugins.withId("com.android.application") {
extensions.getByType(com.android.build.gradle.AppExtension::class.java).compileSdkVersion(36)
}
}

tasks.register<Delete>("clean") {
delete(rootProject.layout.buildDirectory)
}
