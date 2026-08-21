import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../regras/regras.dart';

class ResultadoDaLeitura {
  const ResultadoDaLeitura({
    required this.codigo,
    required this.destino,
    required this.mensagem,
  });

  final String codigo;
  final String destino;
  final String mensagem;
}

class FalhaNaLeitura implements Exception {
  const FalhaNaLeitura(this.mensagem, {this.statusCode});

  final String mensagem;
  final int? statusCode;

  bool get ehDuplicado => statusCode == 409;
}

class ApiDeLeitura {
  const ApiDeLeitura();

  // OBS: em outro computador ou celular, informe o IP da máquina da API:
  // flutter run --dart-define=ENDERECO_API=http://192.168.0.10:3001
  static const endereco = String.fromEnvironment(
    'ENDERECO_API',
    defaultValue: 'http://127.0.0.1:3001',
  );

  Future<ResultadoDaLeitura> enviar(
    String codigo, {
    required DestinoLeitura modo,
  }) async {
    late final http.Response resposta;

    try {
      resposta = await http
          .post(
            Uri.parse('$endereco/leituras'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'codigo': codigo, 'modo': modo.chave}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const FalhaNaLeitura('A API demorou para responder.');
    } on http.ClientException {
      throw const FalhaNaLeitura('Não foi possível conectar com a API.');
    }

    final dados = _lerResposta(resposta.body);

    if (resposta.statusCode != 201) {
      throw FalhaNaLeitura(
        dados['erro']?.toString() ?? 'Não foi possível salvar a leitura.',
        statusCode: resposta.statusCode,
      );
    }

    return ResultadoDaLeitura(
      codigo: dados['codigo'].toString(),
      destino: dados['destino'].toString(),
      mensagem: dados['mensagem'].toString(),
    );
  }

  Map<String, dynamic> _lerResposta(String conteudo) {
    try {
      final dados = jsonDecode(conteudo);
      return dados is Map<String, dynamic> ? dados : {};
    } on FormatException {
      return {};
    }
  }
}
