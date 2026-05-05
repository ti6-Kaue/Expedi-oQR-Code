// Sons do scanner no Android.
// Observacao: chama codigo nativo via MethodChannel e usa som do Flutter como fallback.
import 'package:flutter/services.dart';

class ScannerSoundFeedback {
  static const _channel = MethodChannel('qr_datamatrix_reader/sounds');

  static Future<void> scan() async {
    try {
      await _channel.invokeMethod<void>('scan');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> error() async {
    try {
      await _channel.invokeMethod<void>('error');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.alert);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
