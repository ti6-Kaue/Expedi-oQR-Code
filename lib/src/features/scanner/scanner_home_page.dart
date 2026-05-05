// Tela principal do scanner.
// Observacao: aqui ficam layout, camera, leitura QR/DataMatrix, botao salvar e historico.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_colors.dart';
import '../../models/parsed_gs1_code.dart';
import '../../models/saved_scan.dart';
import '../../services/local_scan_storage.dart';
import '../../services/remote_scan_service.dart';
import '../../services/scanner_sound_feedback.dart';
import '../../utils/barcode_format_label.dart';

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.dataMatrix],
  );
  final _localStorage = LocalScanStorage();

  List<SavedScan> _savedScans = <SavedScan>[];
  Barcode? _lastBarcode;
  bool _cameraOpen = false;
  bool _isSaving = false;

  String? get _currentValue {
    final value = _lastBarcode?.rawValue ?? _lastBarcode?.displayValue;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedScans());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _loadSavedScans() async {
    final scans = await _localStorage.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedScans = scans;
    });
  }

  void _handleDetect(BarcodeCapture capture) {
    Barcode? foundBarcode;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      if (value != null && value.trim().isNotEmpty) {
        foundBarcode = barcode;
        break;
      }
    }

    if (foundBarcode == null || !mounted) {
      return;
    }

    unawaited(ScannerSoundFeedback.scan());

    setState(() {
      _lastBarcode = foundBarcode;
    });
  }

  Future<void> _saveCurrent() async {
    final currentValue = _currentValue;
    final barcode = _lastBarcode;
    if (currentValue == null || barcode == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final scan = SavedScan(
        value: currentValue,
        format: barcodeFormatLabel(barcode.format),
        savedAt: DateTime.now(),
      );
      final nextScans = <SavedScan>[scan, ..._savedScans];
      var saveMessage = 'Leitura salva no celular.';

      await _localStorage.saveAll(nextScans);

      if (!mounted) {
        return;
      }

      setState(() {
        _savedScans = nextScans;
      });

      if (RemoteScanService.isConfigured) {
        try {
          await RemoteScanService.save(scan);
          saveMessage = 'Leitura salva no celular e no banco.';
        } on TimeoutException {
          saveMessage = 'Salva no celular. Banco demorou para responder.';
        } on Object catch (error) {
          saveMessage = 'Salva no celular. Banco com erro: $error';
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(saveMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _clearSavedScans() async {
    await _localStorage.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedScans = <SavedScan>[];
    });
  }

  Future<void> _runCameraAction(Future<void> Function() action) async {
    try {
      await action();
    } on MobileScannerException catch (error) {
      if (!mounted) {
        return;
      }
      unawaited(ScannerSoundFeedback.error());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera: ${error.errorCode.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _AppHeader(
                savedCount: _savedScans.length,
                cameraOpen: _cameraOpen,
                controller: _controller,
                onToggleTorch: () => _runCameraAction(_controller.toggleTorch),
                onSwitchCamera: () =>
                    _runCameraAction(_controller.switchCamera),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _ScannerFrame(
                  cameraOpen: _cameraOpen,
                  controller: _controller,
                  onDetect: _handleDetect,
                  onStart: () {
                    setState(() {
                      _cameraOpen = true;
                    });
                  },
                ),
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
                  children: [
                    _CurrentReadout(
                      barcode: _lastBarcode,
                      isSaving: _isSaving,
                      onSave: _currentValue == null ? null : _saveCurrent,
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Historico',
                      count: _savedScans.length,
                      onClear: _savedScans.isEmpty ? null : _clearSavedScans,
                    ),
                    const SizedBox(height: 10),
                    if (_savedScans.isEmpty)
                      const _EmptySavedState()
                    else
                      for (final scan in _savedScans)
                        _SavedScanTile(scan: scan),
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
  const _AppHeader({
    required this.savedCount,
    required this.cameraOpen,
    required this.controller,
    required this.onToggleTorch,
    required this.onSwitchCamera,
  });

  final int savedCount;
  final bool cameraOpen;
  final MobileScannerController controller;
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
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
          child: Image.asset('Tdetalmax.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leitor QR/DataMatrix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$savedCount salvo${savedCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.searchSubmenu,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: controller,
          builder: (context, state, child) {
            final torchIsOn = state.torchState == TorchState.on;
            final torchAvailable = state.torchState != TorchState.unavailable;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderIconButton(
                  tooltip: 'Flash',
                  onPressed: torchAvailable && cameraOpen
                      ? onToggleTorch
                      : null,
                  icon: torchIsOn ? Icons.flash_on : Icons.flash_off,
                ),
                const SizedBox(width: 6),
                _HeaderIconButton(
                  tooltip: 'Trocar camera',
                  onPressed: cameraOpen ? onSwitchCamera : null,
                  icon: Icons.cameraswitch,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: colors.surface,
        disabledBackgroundColor: AppColors.footerMuted.withValues(alpha: 0.42),
        foregroundColor: AppColors.menu,
        disabledForegroundColor: AppColors.searchSubmenu,
        fixedSize: const Size.square(44),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 1,
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({
    required this.cameraOpen,
    required this.controller,
    required this.onDetect,
    required this.onStart,
  });

  final bool cameraOpen;
  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.scannerDark,
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
      child: cameraOpen
          ? Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  errorBuilder: (context, error) {
                    return _ScannerError(error: error);
                  },
                  onDetect: onDetect,
                ),
                const IgnorePointer(child: _ScannerOverlay()),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FormatChip(label: 'QR Code'),
                        _FormatChip(label: 'Data Matrix'),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _ScannerStartPanel(onStart: onStart),
    );
  }
}

class _CurrentReadout extends StatelessWidget {
  const _CurrentReadout({
    required this.barcode,
    required this.isSaving,
    required this.onSave,
  });

  final Barcode? barcode;
  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = barcode?.rawValue ?? barcode?.displayValue;
    final hasValue = value != null && value.trim().isNotEmpty;
    final parsedCode = hasValue ? ParsedGs1Code.tryParse(value) : null;

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
                  color: hasValue
                      ? AppColors.footer
                      : AppColors.footerMuted.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasValue ? Icons.check_circle : Icons.document_scanner,
                  color: hasValue ? AppColors.menu : AppColors.searchSubmenu,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ultima leitura',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.searchSubmenu,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (barcode != null)
                      _InlineBadge(label: barcodeFormatLabel(barcode!.format)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (parsedCode != null) ...[
            _ParsedGs1Fields(code: parsedCode),
            const SizedBox(height: 10),
            Text(
              'Codigo original',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.searchSubmenu,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              visibleGs1Value(value!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.searchSubmenu,
                height: 1.25,
              ),
            ),
          ] else
            SelectableText(
              hasValue ? visibleGs1Value(value) : 'Nada lido ainda.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: hasValue
                    ? AppColors.textPrimary
                    : AppColors.searchSubmenu,
                height: 1.25,
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSave,
            icon: isSaving
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text('Salvar leitura'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onClear,
  });

  final String title;
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.searchSubmenu,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Limpar'),
        ),
      ],
    );
  }
}

class _SavedScanTile extends StatelessWidget {
  const _SavedScanTile({required this.scan});

  final SavedScan scan;

  @override
  Widget build(BuildContext context) {
    final parsedCode = scan.parsedCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.footerMuted),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.footer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.menu,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InlineBadge(label: scan.format),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatSavedAt(scan.savedAt),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.searchSubmenu,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                if (parsedCode != null)
                  _ParsedGs1Fields(code: parsedCode, compact: true)
                else
                  SelectableText(
                    visibleGs1Value(scan.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedGs1Fields extends StatelessWidget {
  const _ParsedGs1Fields({required this.code, this.compact = false});

  final ParsedGs1Code code;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fields = code.displayFields;

    return Column(
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          _ParsedGs1FieldRow(field: fields[index], compact: compact),
        ],
      ],
    );
  }
}

class _ParsedGs1FieldRow extends StatelessWidget {
  const _ParsedGs1FieldRow({required this.field, required this.compact});

  final ParsedGs1Field field;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.searchSubmenu,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );
    final valueStyle =
        (compact
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: compact ? 86 : 104,
          child: Text(field.label, style: labelStyle),
        ),
        const SizedBox(width: 8),
        Expanded(child: SelectableText(field.value, style: valueStyle)),
      ],
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  const _EmptySavedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.footerMuted),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.footerMuted.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bookmark_border,
              color: AppColors.searchSubmenu,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma leitura salva ainda.',
              style: TextStyle(
                color: AppColors.searchSubmenu,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerStartPanel extends StatelessWidget {
  const _ScannerStartPanel({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.textPrimary, AppColors.menu],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: -22,
            child: Icon(
              Icons.qr_code_2,
              color: Colors.white.withValues(alpha: 0.05),
              size: 170,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scanner pronto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'QR Code e Data Matrix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Abrir scanner'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.alert,
                      foregroundColor: AppColors.alertText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.searchSubmenu,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScannerError extends StatefulWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  State<_ScannerError> createState() => _ScannerErrorState();
}

class _ScannerErrorState extends State<_ScannerError> {
  @override
  void initState() {
    super.initState();
    unawaited(ScannerSoundFeedback.error());
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.scannerDark),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: AppColors.alert),
              const SizedBox(height: 10),
              Text(
                'Camera indisponivel',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.error.errorCode.name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScannerOverlayPainter());
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    final framePaint = Paint()
      ..color = AppColors.alert
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    final frameSize = size.shortestSide * 0.66;
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );
    final frameRRect = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(18),
    );

    final overlayPath = Path()..addRect(Offset.zero & size);
    final clearPath = Path()..addRRect(frameRRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlayPath, clearPath),
      overlayPaint,
    );

    const cornerLength = 34.0;
    canvas.drawLine(
      Offset(frame.left + 22, frame.center.dy),
      Offset(frame.right - 22, frame.center.dy),
      guidePaint,
    );
    canvas
      ..drawLine(
        frame.topLeft,
        frame.topLeft + const Offset(cornerLength, 0),
        framePaint,
      )
      ..drawLine(
        frame.topLeft,
        frame.topLeft + const Offset(0, cornerLength),
        framePaint,
      )
      ..drawLine(
        frame.topRight,
        frame.topRight + const Offset(-cornerLength, 0),
        framePaint,
      )
      ..drawLine(
        frame.topRight,
        frame.topRight + const Offset(0, cornerLength),
        framePaint,
      )
      ..drawLine(
        frame.bottomLeft,
        frame.bottomLeft + const Offset(cornerLength, 0),
        framePaint,
      )
      ..drawLine(
        frame.bottomLeft,
        frame.bottomLeft + const Offset(0, -cornerLength),
        framePaint,
      )
      ..drawLine(
        frame.bottomRight,
        frame.bottomRight + const Offset(-cornerLength, 0),
        framePaint,
      )
      ..drawLine(
        frame.bottomRight,
        frame.bottomRight + const Offset(0, -cornerLength),
        framePaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
