allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
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
    project.evaluationDependsOn(":app")

    // Stripe y otros plugins con KGP antiguo compilan a JVM 21 por defecto
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val sourceCompat = (project.extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension)?.compileOptions?.sourceCompatibility
            ?: JavaVersion.VERSION_17
        val jvmTargetName = "JVM_" + sourceCompat.toString().replace(".", "_")
        val target = try {
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.valueOf(jvmTargetName)
        } catch (_: IllegalArgumentException) {
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
        compilerOptions {
            jvmTarget.set(target)
        }
    }

    project.ext["compileSdk"] = 37

    configurations.all {
        resolutionStrategy {
            force("androidx.annotation:annotation-experimental:1.3.1")
            force("androidx.exifinterface:exifinterface:1.3.6")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
