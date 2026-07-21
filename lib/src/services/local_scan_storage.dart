// Salvamento local no celular usando SharedPreferences.
// Observacao: mantem historico mesmo se a API/banco estiver sem internet.
// Comunica-se com: scanner_home_page.dart e saved_scan.dart.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_scan.dart';

class LocalScanStorage {
  // Nomes usados para localizar os dados no armazenamento do aparelho.
  static const _storageKey = 'saved_scans';
  static const _scanSoundKey = 'scan_sound';

  Future<List<SavedScan>> load() async {
    // Carrega os textos JSON e transforma cada um novamente em SavedScan.
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
        // Ignora dados antigos ou incompletos.
      }
    }

    return scans;
  }

  Future<void> saveAll(List<SavedScan> scans) async {
    // Converte todas as leituras em JSON e substitui a lista armazenada.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      scans.map((scan) => jsonEncode(scan.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    // Remove apenas o historico; a preferencia de som continua salva.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<String?> loadScanSound() async {
    // Recupera o identificador do ultimo som escolhido.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scanSoundKey);
  }

  Future<void> saveScanSound(String soundId) async {
    // Persiste a escolha para continuar igual quando o app for reaberto.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanSoundKey, soundId);
  }
}
