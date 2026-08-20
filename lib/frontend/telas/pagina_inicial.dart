import 'dart:async';

import 'package:flutter/material.dart';

import '../../regras/regras.dart';
import '../api/api_de_leitura.dart';
import '../componentes/leitor_pela_camera.dart';
import '../cores_do_aplicativo.dart';
import '../servicos/historico_de_leituras.dart';
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
  final _armazenamentoDoHistorico = const HistoricoDeLeituras();

  bool _enviando = false;
  bool _carregandoHistorico = true;
  List<ItemDoHistorico> _historico = [];

  @override
  void initState() {
    super.initState();
    unawaited(_carregarHistorico());
  }

  Future<void> _carregarHistorico() async {
    try {
      final itens = await _armazenamentoDoHistorico.carregar();
      if (!mounted) return;
      setState(() {
        _historico = itens;
        _carregandoHistorico = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoHistorico = false);
    }
  }

  @override
  void dispose() {
    unawaited(_somDaLeitura.dispose());
    super.dispose();
  }

  Future<RetornoDaLeitura> _enviarLeitura(String codigoRecebido) async {
    // OBS: impede duas gravações enquanto a primeira ainda está sendo enviada.
    if (_enviando) {
      return const RetornoDaLeitura(
        situacao: SituacaoDaLeitura.erro,
        mensagem: 'A leitura anterior ainda está sendo processada.',
      );
    }

    var codigo = codigoRecebido.trim();
    try {
      // OBS: limpa o código e define o destino em uma única análise.
      final leitura = Regras.analisarCodigo(codigoRecebido);
      codigo = leitura.codigo;
      setState(() {
        _enviando = true;
      });

      final resultado = await _api.enviar(codigo);
      if (!mounted) {
        return const RetornoDaLeitura(
          situacao: SituacaoDaLeitura.erro,
          mensagem: 'A tela foi fechada durante a leitura.',
        );
      }

      // REGRA 5 - CONTADOR E HISTÓRICO:
      // Somente uma gravação confirmada pela API entra no contador e
      // no histórico. Duplicidades e falhas não chegam a este ponto.
      await _adicionarAoHistorico(leitura.codigo, leitura.destino);
      unawaited(_somDaLeitura.tocarCorreto());
      return RetornoDaLeitura(
        situacao: SituacaoDaLeitura.salva,
        mensagem: resultado.mensagem,
        contabilizada: true,
      );
    } on FormatException {
      // OBS: outros códigos impressos na etiqueta são ignorados sem bip.
      return const RetornoDaLeitura(
        situacao: SituacaoDaLeitura.ignorada,
        mensagem: '',
      );
    } on FalhaNaLeitura catch (erro) {
      if (erro.ehDuplicado) {
        // REGRA 6 - DUPLICADO NÃO CONTA:
        // Toca o aviso, mas não adiciona ao histórico e devolve
        // contabilizada=false para a tela da câmera.
        _registrarFalha(duplicado: true);
        return RetornoDaLeitura(
          situacao: SituacaoDaLeitura.duplicada,
          mensagem: erro.mensagem,
        );
      }

      _registrarFalha();
      return RetornoDaLeitura(
        situacao: SituacaoDaLeitura.erro,
        mensagem: erro.mensagem,
      );
    } catch (_) {
      const mensagem = 'Erro inesperado ao processar a leitura.';
      _registrarFalha();
      return const RetornoDaLeitura(
        situacao: SituacaoDaLeitura.erro,
        mensagem: mensagem,
      );
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _adicionarAoHistorico(
    String codigo,
    DestinoLeitura destino,
  ) async {
    final item = ItemDoHistorico(
      codigo: codigo,
      destino: destino == DestinoLeitura.portalPostal
          ? 'Portal Postal'
          : 'Pedido de Venda',
      lidoEm: DateTime.now(),
    );

    final historicoAtualizado = [item, ..._historico];
    if (mounted) setState(() => _historico = historicoAtualizado);

    try {
      await _armazenamentoDoHistorico.salvar(historicoAtualizado);
    } catch (_) {
      // Uma falha no cache local não deve impedir o envio para a API.
    }
  }

  Future<void> _confirmarLimpeza() async {
    if (_historico.isEmpty) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'A contagem e o histórico salvos neste aparelho serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;
    setState(() => _historico = []);
    try {
      await _armazenamentoDoHistorico.limpar();
    } catch (_) {
      // A interface permanece utilizável mesmo se o cache falhar.
    }
  }

  Future<void> _abrirCamera() async {
    if (_enviando) return;

    // OBS: a câmera permanece aberta e chama _enviarLeitura a cada código.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LeitorPelaCamera(
          aoProcessar: _enviarLeitura,
          quantidadeInicial: _historico.length,
        ),
      ),
    );
  }

  void _registrarFalha({bool duplicado = false}) {
    if (!mounted) return;
    unawaited(
      duplicado ? _somDaLeitura.tocarDuplicado() : _somDaLeitura.tocarErro(),
    );
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
                    _ResumoDoHistorico(
                      quantidade: _historico.length,
                      aoLimpar: _historico.isEmpty ? null : _confirmarLimpeza,
                    ),
                    const SizedBox(height: 14),
                    if (_carregandoHistorico)
                      const Center(child: CircularProgressIndicator())
                    else if (_historico.isEmpty)
                      const _HistoricoVazio()
                    else
                      ..._historico.map((item) => _ItemDoHistorico(item)),
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

class _ResumoDoHistorico extends StatelessWidget {
  const _ResumoDoHistorico({required this.quantidade, required this.aoLimpar});

  final int quantidade;
  final VoidCallback? aoLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.textPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itens bipados',
                  style: TextStyle(
                    color: CoresDoAplicativo.footerMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$quantidade',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: aoLimpar,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _HistoricoVazio extends StatelessWidget {
  const _HistoricoVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoresDoAplicativo.footerMuted),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: CoresDoAplicativo.searchSubmenu,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Nenhum item bipado',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Os códigos válidos aparecerão aqui.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ItemDoHistorico extends StatelessWidget {
  const _ItemDoHistorico(this.item);

  final ItemDoHistorico item;

  @override
  Widget build(BuildContext context) {
    final horario = _formatarData(item.lidoEm);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: CoresDoAplicativo.footerMuted),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: CoresDoAplicativo.background,
          child: Icon(Icons.qr_code_rounded, color: CoresDoAplicativo.menu),
        ),
        title: Text(
          item.codigo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${item.destino}  •  $horario'),
      ),
    );
  }

  String _formatarData(DateTime data) {
    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${doisDigitos(data.day)}/${doisDigitos(data.month)} '
        '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }
}
