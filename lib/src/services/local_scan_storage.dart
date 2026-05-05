// Salvamento local no celular usando SharedPreferences.
// Observacao: mantem historico mesmo se a API/banco estiver sem internet.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_scan.dart';

class LocalScanStorage {
  static const _storageKey = 'saved_scans';

  Future<List<SavedScan>> load() async {
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

    return scans;
  }

  Future<void> saveAll(List<SavedScan> scans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      scans.map((scan) => jsonEncode(scan.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
