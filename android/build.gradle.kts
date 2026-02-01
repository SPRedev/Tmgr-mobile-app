buildscript {
    repositories {
        google()       // needed for Google Services plugin
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1")  // your Android Gradle Plugin
        classpath("com.google.gms:google-services:4.4.0")  // add this for Firebase
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
