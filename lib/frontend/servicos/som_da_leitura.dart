import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Reproduz o aviso sonoro correspondente ao resultado da leitura.
class SomDaLeitura {
  SomDaLeitura() {
    // OBS: informa em qual pasta do frontend estão os arquivos de áudio.
    _reprodutor.audioCache = AudioCache(prefix: 'lib/frontend/recursos/sons/');
  }

  final AudioPlayer _reprodutor = AudioPlayer();

  // OBS: toca somente depois que a API confirmar a gravação no banco.
  Future<void> tocarCorreto() => _tocar('correto.mp3');

  // OBS: toca quando a regra, a API ou a gravação retornar um erro.
  Future<void> tocarErro() => _tocar('erro.mp3');

  Future<void> _tocar(String arquivo) async {
    try {
      // OBS: interrompe o som anterior para não misturar duas leituras rápidas.
      await _reprodutor.stop();
      await _reprodutor.play(AssetSource(arquivo));
    } catch (erro) {
      // O áudio é apenas um aviso; uma falha nele não altera a leitura.
      debugPrint('Não foi possível tocar $arquivo: $erro');
    }
  }

  // OBS: libera o reprodutor quando a tela for fechada.
  Future<void> dispose() => _reprodutor.dispose();
}
