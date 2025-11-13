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
    
    // Force all subprojects (plugins) to use Java 11 as JVM target to match the app
    // This must be applied to both Java and Kotlin compilation
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
        }
    }
    
    // Also configure via extension if available
    plugins.withType<JavaPlugin> {
        configure<JavaPluginExtension> {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
