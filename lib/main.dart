import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QrDataMatrixApp());
}

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

class RemoteScanService {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => _apiBaseUrl.trim().isNotEmpty;

  static Future<void> save(SavedScan scan) async {
    if (!isConfigured) {
      return;
    }

    final baseUrl = _apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final response = await http
        .post(
          Uri.parse('$baseUrl/scans'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(scan.toApiJson()),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteScanException(
        'API retornou HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class RemoteScanException implements Exception {
  const RemoteScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QrDataMatrixApp extends StatelessWidget {
  const QrDataMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00796B))
        .copyWith(
          primary: const Color(0xFF006D77),
          secondary: const Color(0xFFE9A21A),
          surface: Colors.white,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leitor QR/DataMatrix',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(centerTitle: false),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  static const _storageKey = 'saved_scans';

  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.dataMatrix],
  );

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
    final prefs = await SharedPreferences.getInstance();
    final storedValues = prefs.getStringList(_storageKey) ?? const <String>[];
    final scans = <SavedScan>[];

    for (final storedValue in storedValues) {
      try {
        final decoded = jsonDecode(storedValue);
        if (decoded is Map<String, Object?>) {
          scans.add(SavedScan.fromJson(decoded));
        }
      } on FormatException {
        // Ignore old or incomplete test data.
      }
    }

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
      String saveMessage = 'Leitura salva no celular.';

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

      final nextScans = <SavedScan>[scan, ..._savedScans];
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        _storageKey,
        nextScans.map((scan) => jsonEncode(scan.toJson())).toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedScans = nextScans;
      });

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

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
      backgroundColor: const Color(0xFFF3F6F7),
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
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
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

class SavedScan {
  const SavedScan({
    required this.value,
    required this.format,
    required this.savedAt,
  });

  factory SavedScan.fromJson(Map<String, Object?> json) {
    final savedAtValue = json['savedAt'] as String?;

    return SavedScan(
      value: json['value'] as String? ?? '',
      format: json['format'] as String? ?? 'Desconhecido',
      savedAt: savedAtValue == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(savedAtValue) ??
                DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String value;
  final String format;
  final DateTime savedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'value': value,
      'format': format,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toApiJson() {
    return <String, Object?>{'value': value, 'format': format};
  }
}

String barcodeFormatLabel(BarcodeFormat format) {
  return switch (format) {
    BarcodeFormat.qrCode => 'QR Code',
    BarcodeFormat.dataMatrix => 'Data Matrix',
    BarcodeFormat.unknown => 'Desconhecido',
    _ => format.name,
  };
}

String formatSavedAt(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
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
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_2, color: Colors.white),
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
                  color: colors.onSurfaceVariant,
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
        disabledBackgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.primary,
        disabledForegroundColor: colors.outline,
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
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
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasValue ? Icons.check_circle : Icons.document_scanner,
                  color: hasValue ? colors.primary : colors.onSurfaceVariant,
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
                        color: colors.onSurfaceVariant,
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
          SelectableText(
            hasValue ? value : 'Nada lido ainda.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: hasValue ? colors.onSurface : colors.onSurfaceVariant,
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
    final colors = Theme.of(context).colorScheme;

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
                  color: colors.secondaryContainer,
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
                      color: colors.onSecondaryContainer,
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
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
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: colors.primary),
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
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                SelectableText(
                  scan.value,
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

class _EmptySavedState extends StatelessWidget {
  const _EmptySavedState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bookmark_border, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma leitura salva ainda.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
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
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F26), Color(0xFF173B3F)],
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scanner pronto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'QR Code e Data Matrix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Abrir scanner'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
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
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: colors.onSecondaryContainer,
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
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF101820)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined, color: colors.secondary),
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
      ..color = const Color(0xFFE9A21A)
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
