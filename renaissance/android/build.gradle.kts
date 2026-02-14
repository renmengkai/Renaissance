allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for audiotagger namespace issue
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (androidExtension != null && androidExtension.namespace == null) {
                val groupStr = project.group.toString()
                if (groupStr.isNotEmpty() && groupStr != "unspecified") {
                    androidExtension.namespace = groupStr
                } else {
                    // Fallback namespace for audiotagger
                    androidExtension.namespace = "com.nicolorebaioli.audiotagger"
                }
            }
        }
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
