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
    afterEvaluate {
        project.extensions.findByName("android")?.let { androidExt ->
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(androidExt) as String?
                if (namespace == null || namespace.isEmpty()) {
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(androidExt, project.group.toString())
                }
            } catch (e: Exception) {
                // ignore
            }
            try {
                val setCompileSdkVersion = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                setCompileSdkVersion.invoke(androidExt, 36)
            } catch (e: Exception) {
                // ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
