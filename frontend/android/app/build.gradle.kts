plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
android {
    namespace = "com.example.forja_trabajo"
    
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.forja_trabajo"
        
        // 🔴 2. NO USES flutter.minSdkVersion. 
        // Forzalo a 21 para que Firebase y Geolocator no den errores de compatibilidad.
        minSdk = flutter.minSdkVersion 
        
        // 🟡 3. TRUCO DE ESTABILIDAD:
        // Compilamos con la 36 (para que Gradle no llore), 
        // pero le decimos al emulador que se comporte como la 35.
        targetSdk = 35 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
}
