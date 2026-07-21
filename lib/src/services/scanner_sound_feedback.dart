// Sons do scanner no Android.
// Observacao: chama codigo nativo via MethodChannel e usa som do Flutter como fallback.
// Comunica-se com: scanner_home_page.dart, local_scan_storage.dart e
// android/app/src/main/kotlin/.../MainActivity.kt.
import 'package:flutter/services.dart';

enum ScanSound {
  // id e enviado ao Android; label e o texto mostrado no menu.
  beep('beep', 'Beep'),
  confirmation('confirmation', 'Confirmação'),
  notification('notification', 'Aviso'),
  silent('silent', 'Sem som');

  const ScanSound(this.id, this.label);

  final String id;
  final String label;

  static ScanSound fromId(String? id) {
    // Converte o texto salvo no aparelho novamente para uma opcao do enum.
    return ScanSound.values.firstWhere(
      (sound) => sound.id == id,
      orElse: () => ScanSound.beep,
    );
  }
}

class ScannerSoundFeedback {
  // Este nome precisa ser exatamente igual ao MethodChannel da MainActivity.
  static const _channel = MethodChannel('qr_datamatrix_reader/sounds');

  static Future<void> scan(ScanSound sound) async {
    if (sound == ScanSound.silent) {
      return;
    }

    // Solicita ao codigo Android que toque o som selecionado.
    try {
      await _channel.invokeMethod<void>('scan', <String, String>{
        'sound': sound.id,
      });
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> error() async {
    // Som separado usado quando a camera ou o scanner apresenta erro.
    try {
      await _channel.invokeMethod<void>('error');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.alert);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
