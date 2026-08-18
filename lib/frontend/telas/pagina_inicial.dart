import 'dart:async';

import 'package:flutter/material.dart';

import '../../regras/regras.dart';
import '../api/api_de_leitura.dart';
import '../componentes/leitor_pela_camera.dart';
import '../cores_do_aplicativo.dart';
import '../servicos/som_da_leitura.dart';

class PaginaInicial extends StatefulWidget {
  const PaginaInicial({super.key});

  @override
  State<PaginaInicial> createState() => _PaginaInicialState();
}

class _PaginaInicialState extends State<PaginaInicial> {
  // OBS: ApiDeLeitura é o arquivo responsável pelo POST.
  final _api = const ApiDeLeitura();

  // OBS: este serviço escolhe entre correto.mp3 e erro.mp3.
  final _somDaLeitura = SomDaLeitura();

  bool _enviando = false;
  bool? _salvou;
  String _mensagem = 'Aguardando a primeira leitura';
  String? _ultimoCodigo;
  String? _ultimoDestino;

  @override
  void dispose() {
    unawaited(_somDaLeitura.dispose());
    super.dispose();
  }

  Future<void> _enviarLeitura(String codigoRecebido) async {
    // OBS: impede duas gravações enquanto a primeira ainda está sendo enviada.
    if (_enviando) return;

    final codigo = codigoRecebido.trim();

    try {
      // OBS: aplica a regra local antes de enviar; o backend confere novamente.
      final destinoPrevisto = Regras.definirDestino(codigo);
      setState(() {
        _enviando = true;
        _salvou = null;
        _mensagem = destinoPrevisto == DestinoLeitura.portalPostal
            ? 'Enviando para o Portal Postal...'
            : 'Enviando para Pedido de Venda...';
      });

      final resultado = await _api.enviar(codigo);
      if (!mounted) return;

      setState(() {
        _salvou = true;
        _mensagem = resultado.mensagem;
        _ultimoCodigo = resultado.codigo;
        _ultimoDestino = resultado.destino;
      });
      unawaited(_somDaLeitura.tocarCorreto());
    } on FormatException catch (erro) {
      _mostrarErro(erro.message);
    } on FalhaNaLeitura catch (erro) {
      _mostrarErro(erro.mensagem);
    } catch (_) {
      _mostrarErro('Erro inesperado ao processar a leitura.');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _abrirCamera() async {
    if (_enviando) return;

    // OBS: abre a câmera e aguarda o código detectado pelo mobile_scanner.
    final codigo = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const LeitorPelaCamera()));

    if (!mounted || codigo == null) return;

    // OBS: o código segue para as regras, POST, banco e aviso sonoro.
    await _enviarLeitura(codigo);
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _salvou = false;
      _mensagem = mensagem;
    });
    unawaited(_somDaLeitura.tocarErro());
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: CoresDoAplicativo.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _Cabecalho(),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: PainelDaCamera(
                  enviando: _enviando,
                  aoAbrirCamera: _abrirCamera,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cores.surface,
                  border: const Border(
                    top: BorderSide(color: CoresDoAplicativo.footerMuted),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _CartaoDoResultado(
                      salvou: _salvou,
                      mensagem: _mensagem,
                      codigo: _ultimoCodigo,
                      destino: _ultimoDestino,
                    ),
                    const SizedBox(height: 18),
                    const _RegrasDaLeitura(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: CoresDoAplicativo.menu,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: CoresDoAplicativo.menu.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'lib/frontend/recursos/logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expedição',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Leitor de códigos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresDoAplicativo.searchSubmenu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.circle, size: 10, color: Colors.green),
        const SizedBox(width: 6),
        const Text('Pronto', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CartaoDoResultado extends StatelessWidget {
  const _CartaoDoResultado({
    required this.salvou,
    required this.mensagem,
    required this.codigo,
    required this.destino,
  });

  final bool? salvou;
  final String mensagem;
  final String? codigo;
  final String? destino;

  @override
  Widget build(BuildContext context) {
    final cor = salvou == null
        ? CoresDoAplicativo.searchSubmenu
        : salvou!
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: CoresDoAplicativo.footerMuted),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            salvou == true ? Icons.check_circle : Icons.info_outline,
            color: cor,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensagem,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (codigo != null) ...[
                  const SizedBox(height: 6),
                  Text('Código: $codigo'),
                  Text('Destino: $destino'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegrasDaLeitura extends StatelessWidget {
  const _RegrasDaLeitura();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoresDoAplicativo.footerMuted),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regras da leitura',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text('• 13 ou 14 caracteres e termina com BR: Portal Postal.'),
          Text('• Demais códigos numéricos: Pedido de Venda.'),
        ],
      ),
    );
  }
}
