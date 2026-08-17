import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _AppHeader(),
            ),
            const Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _MainPanel(),
              ),
            ),
            Expanded(
              flex: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.footerMuted),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: const [
                    _ContentCard(),
                    SizedBox(height: 18),
                    _SectionHeader(),
                    SizedBox(height: 10),
                    _EmptyState(),
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

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.menu,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.menu.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
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
                  color: AppColors.searchSubmenu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          tooltip: 'Ação',
          icon: Icons.tune_rounded,
          colorScheme: colors,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          tooltip: 'Visualização',
          icon: Icons.visibility_outlined,
          colorScheme: colors,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          tooltip: 'Opções',
          icon: Icons.more_horiz_rounded,
          colorScheme: colors,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.colorScheme,
  });

  final String tooltip;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {},
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: AppColors.menu,
        fixedSize: const Size.square(44),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 1,
      ),
    );
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.menu.withValues(alpha: 0.22),
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
                  color: AppColors.footerMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 190,
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.alert,
                    foregroundColor: AppColors.alertText,
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

class _ContentCard extends StatelessWidget {
  const _ContentCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: AppColors.footerMuted),
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
                  color: AppColors.footerMuted.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: AppColors.searchSubmenu,
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
                        color: AppColors.searchSubmenu,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Aguardando informações',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
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
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Use este espaço para apresentar as informações principais.',
              style: TextStyle(color: AppColors.searchSubmenu),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.menu,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

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
            color: AppColors.footerMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '0',
            style: TextStyle(
              color: AppColors.menu,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.footerMuted),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppColors.searchSubmenu,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum conteúdo adicionado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.searchSubmenu,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
