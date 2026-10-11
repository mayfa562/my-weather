allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Android outputs in the workspace build directory so Flutter can
// discover artifacts such as build/app/outputs/flutter-apk/app-debug.apk.
rootProject.layout.buildDirectory = rootProject.layout.projectDirectory.dir("../build")

subprojects {
    project.layout.buildDirectory = rootProject.layout.buildDirectory.dir(project.name)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
