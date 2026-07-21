// Activity Android principal do app Flutter.
// Observacao: aqui fica o canal nativo que toca beep de leitura e som de erro.
// Comunica-se com: lib/src/services/scanner_sound_feedback.dart.
package com.example.qr_datamatrix_reader

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // ToneGenerator usa os sons simples que ja existem no Android.
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)

        // MethodChannel recebe mensagens enviadas pelo codigo Dart.
        // O nome do canal deve ser igual nos dois arquivos.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qr_datamatrix_reader/sounds",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scan" -> {
                    // O argumento sound define qual som sera usado em uma leitura.
                    when (call.argument<String>("sound")) {
                        "confirmation" -> playTone(ToneGenerator.TONE_PROP_ACK, 180)
                        "notification" -> playTone(ToneGenerator.TONE_PROP_PROMPT, 220)
                        "silent" -> Unit
                        else -> playTone(ToneGenerator.TONE_PROP_BEEP, 150)
                    }
                    result.success(null)
                }

                "error" -> {
                    // Erros de camera sempre usam um som de alerta separado.
                    playTone(ToneGenerator.TONE_SUP_ERROR, 300)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // Libera o recurso de audio quando o aplicativo e encerrado.
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private fun playTone(toneType: Int, durationMs: Int) {
        // Inicia o som escolhido durante a quantidade de milissegundos recebida.
        toneGenerator?.startTone(toneType, durationMs)
    }
}
