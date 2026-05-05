package com.example.qr_datamatrix_reader

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qr_datamatrix_reader/sounds",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scan" -> {
                    playTone(ToneGenerator.TONE_PROP_BEEP, 150)
                    result.success(null)
                }

                "error" -> {
                    playTone(ToneGenerator.TONE_SUP_ERROR, 300)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private fun playTone(toneType: Int, durationMs: Int) {
        toneGenerator?.startTone(toneType, durationMs)
    }
}
