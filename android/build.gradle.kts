allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Add Google services classpath so the Android app can apply the plugin when
// using the manual Firebase setup. This uses the Gradle buildscript block.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Use a recent version; adjust if needed when Gradle sync complains.
        classpath("com.google.gms:google-services:4.3.15")
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
