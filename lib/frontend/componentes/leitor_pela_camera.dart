import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../cores_do_aplicativo.dart';

/// Painel da página inicial que abre a câmera do celular.
class PainelDaCamera extends StatelessWidget {
  const PainelDaCamera({
    required this.enviando,
    required this.aoAbrirCamera,
    super.key,
  });

  // OBS: enquanto a API processa, o botão fica bloqueado para evitar repetição.
  final bool enviando;

  // OBS: a página principal fornece a função que abre a câmera.
  final VoidCallback aoAbrirCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.textPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: CoresDoAplicativo.menu.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 58,
              ),
              const SizedBox(height: 14),
              Text(
                enviando ? 'Processando leitura...' : 'Pronto para escanear',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use a câmera do celular para ler o código.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CoresDoAplicativo.footerMuted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: enviando ? null : aoAbrirCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Abrir câmera'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre a câmera e devolve o primeiro código encontrado.
class LeitorPelaCamera extends StatefulWidget {
  const LeitorPelaCamera({super.key});

  @override
  State<LeitorPelaCamera> createState() => _LeitorPelaCameraState();
}

class _LeitorPelaCameraState extends State<LeitorPelaCamera> {
  // OBS: noDuplicates evita repetir continuamente o mesmo código na câmera.
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // OBS: esta trava garante que somente uma leitura volte para a página.
  bool _codigoEntregue = false;

  Future<void> _aoDetectar(BarcodeCapture captura) async {
    if (_codigoEntregue) return;

    // OBS: uma imagem pode conter vários códigos; usamos o primeiro preenchido.
    String? codigo;
    for (final item in captura.barcodes) {
      final valor = item.rawValue?.trim();
      if (valor != null && valor.isNotEmpty) {
        codigo = valor;
        break;
      }
    }

    if (codigo == null) return;
    _codigoEntregue = true;

    // OBS: para a câmera antes de devolver o código e evita nova detecção.
    await _camera.stop();
    if (mounted) Navigator.of(context).pop(codigo);
  }

  @override
  void dispose() {
    unawaited(_camera.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ler pela câmera'),
        actions: [
          IconButton(
            tooltip: 'Ligar ou desligar a lanterna',
            onPressed: _camera.toggleTorch,
            icon: const Icon(Icons.flash_on_rounded),
          ),
          IconButton(
            tooltip: 'Trocar câmera',
            onPressed: _camera.switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _camera,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível abrir a câmera.\n$erro',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // OBS: a moldura é apenas uma orientação visual para o operador.
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Centralize o código dentro da moldura',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
