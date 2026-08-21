import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../regras/regras.dart';
import '../cores_do_aplicativo.dart';

enum SituacaoDaLeitura { salva, duplicada, ignorada, erro }

/// Resultado devolvido à câmera depois que a API processa o código.
class RetornoDaLeitura {
  const RetornoDaLeitura({
    required this.situacao,
    required this.mensagem,
    this.contabilizada = false,
  });

  final SituacaoDaLeitura situacao;
  final String mensagem;
  final bool contabilizada;

  bool get continuaAutomaticamente =>
      situacao == SituacaoDaLeitura.salva ||
      situacao == SituacaoDaLeitura.ignorada;
}

/// Painel da página inicial que abre a câmera do celular.
class PainelDaCamera extends StatelessWidget {
  const PainelDaCamera({
    required this.enviando,
    required this.aoAbrirCamera,
    super.key,
  });

  final bool enviando;
  final ValueChanged<DestinoLeitura> aoAbrirCamera;

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
                enviando ? 'Processando leitura...' : 'Escolha o tipo de bipagem',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecione o tipo de código antes de abrir a câmera.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CoresDoAplicativo.footerMuted),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enviando
                      ? null
                      : () => aoAbrirCamera(DestinoLeitura.pedidoDeVenda),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Bipar Pedido de Venda'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enviando
                      ? null
                      : () => aoAbrirCamera(DestinoLeitura.portalPostal),
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Bipar Pedido Postal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mantém a câmera aberta e processa uma leitura por vez.
class LeitorPelaCamera extends StatefulWidget {
  const LeitorPelaCamera({
    required this.aoProcessar,
    required this.quantidadeInicial,
    required this.modo,
    super.key,
  });

  // OBS: envia o código para as regras, API e banco sem fechar esta tela.
  final Future<RetornoDaLeitura> Function(String codigo) aoProcessar;
  final int quantidadeInicial;
  final DestinoLeitura modo;

  @override
  State<LeitorPelaCamera> createState() => _LeitorPelaCameraState();
}

class _LeitorPelaCameraState extends State<LeitorPelaCamera> {
  // OBS: a câmera é parada logo após detectar um código; isso evita repetição
  // automática enquanto o operador ainda está apontando para a etiqueta.
  final _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _processando = false;
  String? _codigoLido;
  RetornoDaLeitura? _resultado;
  final Set<String> _codigosIgnorados = {};
  late int _quantidade;

  @override
  void initState() {
    super.initState();
    _quantidade = widget.quantidadeInicial;
  }

  Future<void> _aoDetectar(BarcodeCapture captura) async {
    if (_processando || _resultado != null) return;

    String? codigo;
    for (final item in captura.barcodes) {
      final valor = item.rawValue?.trim();
      if (valor != null && valor.isNotEmpty) {
        codigo = valor;
        break;
      }
    }
    if (codigo == null) return;

    // OBS: códigos da mesma etiqueta que não atendem às regras são ignorados
    // silenciosamente nas próximas imagens da câmera.
    if (_codigosIgnorados.contains(codigo)) return;

    setState(() {
      _processando = true;
      _codigoLido = codigo;
    });

    // OBS: permanece nesta tela, mas pausa a câmera durante a gravação.
    await _camera.stop();
    final resultado = await widget.aoProcessar(codigo);

    if (!mounted) return;

    // REGRA: SOMENTE LEITURA SALVA AUMENTA O CONTADOR
    // O backend precisa ter confirmado a gravação. Em duplicidade, erro ou
    // código inválido, contabilizada vem como false e o total não muda.
    if (resultado.contabilizada) {
      setState(() => _quantidade++);
    }

    if (resultado.continuaAutomaticamente) {
      await _continuarAutomaticamente(codigo, resultado.situacao);
      return;
    }

    // Somente erro ou duplicidade interrompem a leitura contínua.
    setState(() {
      _resultado = resultado;
      _processando = false;
    });
  }

  Future<void> _continuarAutomaticamente(
    String codigo,
    SituacaoDaLeitura situacao,
  ) async {
    // REGRA: CÓDIGO FORA DO PADRÃO
    // Guarda o código inválido enquanto a câmera estiver aberta para não
    // tentar processar repetidamente outro código impresso na mesma etiqueta.
    if (situacao == SituacaoDaLeitura.ignorada) {
      _codigosIgnorados.add(codigo);
    } else {
      // Dá tempo para o operador retirar a etiqueta que foi salva.
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    if (!mounted) return;
    await _camera.start();
    if (!mounted) return;
    setState(() {
      _codigoLido = null;
      _processando = false;
    });
  }

  Future<void> _escanearProximo() async {
    // OBS: o operador confirma que retirou a etiqueta anterior antes de seguir.
    setState(() {
      _resultado = null;
      _codigoLido = null;
      _processando = true;
    });
    await _camera.start();
    if (mounted) setState(() => _processando = false);
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
        title: Text('Bipando ${widget.modo.rotulo}'),
        actions: [
          IconButton(
            tooltip: 'Ligar ou desligar a lanterna',
            onPressed: _resultado == null ? _camera.toggleTorch : null,
            icon: const Icon(Icons.flash_on_rounded),
          ),
          IconButton(
            tooltip: 'Trocar câmera',
            onPressed: _resultado == null ? _camera.switchCamera : null,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, restricoes) {
          final tamanho = restricoes.biggest;
          final largura = math.min(tamanho.width * 0.9, 380.0);
          final altura = math.min(tamanho.height * 0.22, 150.0);
          final areaDeLeitura = Rect.fromCenter(
            center: tamanho.center(Offset.zero),
            width: largura,
            height: altura,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // OBS: somente códigos que cruzarem esta área serão detectados.
              MobileScanner(
                controller: _camera,
                scanWindow: areaDeLeitura,
                scanWindowUpdateThreshold: 1,
                onDetect: _aoDetectar,
                errorBuilder: (context, erro) => Center(
                  child: Text(
                    'Não foi possível abrir a câmera.\n$erro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // OBS: uma única camada escurece o exterior e desenha a moldura.
              IgnorePointer(
                child: CustomPaint(painter: _MascaraDaCamera(areaDeLeitura)),
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _IndicadorQuantidade(quantidade: _quantidade),
              ),
              if (_processando)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_resultado != null)
                _AvisoDaLeitura(
                  resultado: _resultado!,
                  codigo: _codigoLido!,
                  aoContinuar: _escanearProximo,
                )
              else if (!_processando)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Posicione somente o código desejado dentro da moldura',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _IndicadorQuantidade extends StatelessWidget {
  const _IndicadorQuantidade({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.textPrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Itens bipados',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$quantidade',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoDaLeitura extends StatelessWidget {
  const _AvisoDaLeitura({
    required this.resultado,
    required this.codigo,
    required this.aoContinuar,
  });

  final RetornoDaLeitura resultado;
  final String codigo;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) {
    final duplicada = resultado.situacao == SituacaoDaLeitura.duplicada;
    final cor = duplicada ? Colors.orange : Colors.red;

    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                duplicada ? Icons.content_copy_rounded : Icons.error_rounded,
                color: cor,
                size: 52,
              ),
              const SizedBox(height: 10),
              Text(
                resultado.mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Código lido: $codigo'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: aoContinuar,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear próximo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascaraDaCamera extends CustomPainter {
  const _MascaraDaCamera(this.areaDeLeitura);

  final Rect areaDeLeitura;

  @override
  void paint(Canvas canvas, Size size) {
    final abertura = RRect.fromRectAndRadius(
      areaDeLeitura,
      const Radius.circular(12),
    );
    final exterior = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(abertura),
    );

    canvas.drawPath(exterior, Paint()..color = const Color(0x77000000));
    canvas.drawRRect(
      abertura,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_MascaraDaCamera anterior) =>
      anterior.areaDeLeitura != areaDeLeitura;
}
