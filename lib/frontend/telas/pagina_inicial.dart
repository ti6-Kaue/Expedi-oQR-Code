import 'package:flutter/material.dart';

import '../cores_do_aplicativo.dart';

class PaginaInicial extends StatelessWidget {
  const PaginaInicial({super.key});

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
            const Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _PainelPrincipal(),
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
                  children: const [
                    _CartaoDeConteudo(),
                    SizedBox(height: 18),
                    _CabecalhoDaSecao(),
                    SizedBox(height: 10),
                    _EstadoVazio(),
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
                'Título do projeto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Informação complementar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresDoAplicativo.searchSubmenu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const _BotaoDoCabecalho(icone: Icons.tune_rounded, dica: 'Ação'),
        const SizedBox(width: 6),
        const _BotaoDoCabecalho(
          icone: Icons.visibility_outlined,
          dica: 'Visualização',
        ),
        const SizedBox(width: 6),
        const _BotaoDoCabecalho(
          icone: Icons.more_horiz_rounded,
          dica: 'Opções',
        ),
      ],
    );
  }
}

class _BotaoDoCabecalho extends StatelessWidget {
  const _BotaoDoCabecalho({required this.icone, required this.dica});

  final IconData icone;
  final String dica;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: dica,
      onPressed: () {},
      icon: Icon(icone),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: CoresDoAplicativo.menu,
        fixedSize: const Size.square(44),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 1,
      ),
    );
  }
}

class _PainelPrincipal extends StatelessWidget {
  const _PainelPrincipal();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CoresDoAplicativo.textPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: CoresDoAplicativo.menu.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Área principal',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Espaço reservado para o conteúdo do novo projeto',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CoresDoAplicativo.footerMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 190,
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ação principal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoDeConteudo extends StatelessWidget {
  const _CartaoDeConteudo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: CoresDoAplicativo.footerMuted),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresDoAplicativo.footerMuted.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: CoresDoAplicativo.searchSubmenu,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bloco de conteúdo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: CoresDoAplicativo.searchSubmenu,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Aguardando informações',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoresDoAplicativo.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Use este espaço para apresentar as informações principais.',
              style: TextStyle(color: CoresDoAplicativo.searchSubmenu),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: CoresDoAplicativo.menu,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Botão de ação'),
          ),
        ],
      ),
    );
  }
}

class _CabecalhoDaSecao extends StatelessWidget {
  const _CabecalhoDaSecao();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Seção secundária',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: CoresDoAplicativo.footerMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '0',
            style: TextStyle(
              color: CoresDoAplicativo.menu,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Ação')),
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: CoresDoAplicativo.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoresDoAplicativo.footerMuted),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: CoresDoAplicativo.searchSubmenu,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum conteúdo adicionado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CoresDoAplicativo.searchSubmenu,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
