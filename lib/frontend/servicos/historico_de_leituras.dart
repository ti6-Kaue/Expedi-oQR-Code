import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemDoHistorico {
  const ItemDoHistorico({
    required this.codigo,
    required this.destino,
    required this.lidoEm,
  });

  final String codigo;
  final String destino;
  final DateTime lidoEm;

  Map<String, String> toJson() => {
    'codigo': codigo,
    'destino': destino,
    'lidoEm': lidoEm.toIso8601String(),
  };

  static ItemDoHistorico? fromJson(String conteudo) {
    try {
      final dados = jsonDecode(conteudo);
      if (dados is! Map<String, dynamic>) return null;

      final codigo = dados['codigo']?.toString();
      final destino = dados['destino']?.toString();
      final lidoEm = DateTime.tryParse(dados['lidoEm']?.toString() ?? '');
      if (codigo == null || destino == null || lidoEm == null) return null;

      return ItemDoHistorico(codigo: codigo, destino: destino, lidoEm: lidoEm);
    } on FormatException {
      return null;
    }
  }
}

class HistoricoDeLeituras {
  const HistoricoDeLeituras();

  // REGRA: HISTÓRICO LOCAL
  // Esta chave guarda no aparelho apenas as leituras confirmadas pela API.
  // Os dados continuam disponíveis depois que o aplicativo for fechado.
  static const _chave = 'historico_de_leituras_validas';

  Future<List<ItemDoHistorico>> carregar() async {
    final preferencias = await SharedPreferences.getInstance();
    final itens = preferencias.getStringList(_chave) ?? const [];
    return itens
        .map(ItemDoHistorico.fromJson)
        .whereType<ItemDoHistorico>()
        .toList();
  }

  Future<void> salvar(List<ItemDoHistorico> itens) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setStringList(
      _chave,
      itens.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> limpar() async {
    // REGRA: BOTÃO LIMPAR
    // Remove somente o histórico e o contador deste aparelho. Esta operação
    // não exclui nenhum registro das tabelas do banco de dados.
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chave);
  }
}
