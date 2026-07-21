// Build Gradle do modulo Android app.
// Observacao: aqui ficam applicationId, minSdk, versao e assinatura debug.
// Comunica-se com: pubspec.yaml, Gradle Wrapper e pasta android/app/src.
plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin Gradle do Flutter deve ser aplicado depois dos plugins Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // namespace identifica as classes Android deste projeto.
    namespace = "com.example.qr_datamatrix_reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Java 17 e usado para compilar os plugins Android.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Defina um identificador unico para o aplicativo.
        applicationId = "com.example.qr_datamatrix_reader"
        // Estes valores podem ser ajustados conforme as necessidades do aplicativo.
        // Mais informacoes: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionCode e versionName vem do campo version em pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Adicione uma configuracao de assinatura para a versao de producao.
            // Por enquanto, usa as chaves de depuracao para permitir `flutter run --release`.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // Informa que o projeto Flutter esta duas pastas acima de android/app.
    source = "../.."
}
