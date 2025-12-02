allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

dependencies {
    implementation("androidx.recyclerview:recyclerview:1.2.1") // Per la lista
    implementation("com.google.api-client:google-api-client-android:1.33.2") // API Google
    implementation("com.google.apis:google-api-services-calendar:v3-rev305-1.25.0") // Google Calendar API
}

// Configura una nuova directory di build per il progetto principale
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Configura una nuova directory di build per i sottoprogetti
subprojects {
    layout.buildDirectory.set(newBuildDir.dir(project.name))
}

// Assicurati che il progetto "app" venga valutato prima degli altri
subprojects {
    evaluationDependsOn(":app")
}

// Task per pulire la directory di build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}