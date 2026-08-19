enum DestinoLeitura { portalPostal, pedidoDeVenda }

class Regras {
  const Regras._();

  // OBS: remove caracteres de controle e extrai o número do pedido quando
  // o código da câmera vier com prefixos, como ocorre em alguns Data Matrix.
  static String normalizarCodigo(String codigoLido) {
    final semControles = codigoLido
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .trim();

    // Alguns leitores acrescentam o identificador AIM "]d2" ao Data Matrix.
    final codigo = semControles.replaceFirst(RegExp(r'^\][A-Za-z]\d'), '');

    final codigoPostal =
        codigo.length == 13 && codigo.toUpperCase().endsWith('BR');
    if (codigoPostal) return codigo;

    final gruposNumericos = RegExp(r'\d+')
        .allMatches(codigo)
        .map((resultado) => resultado.group(0)!)
        .where((numero) => numero.length == 5 || numero.length == 6)
        .toList();

    // Aceita somente um grupo possível para não salvar o número errado.
    if (gruposNumericos.length == 1) return gruposNumericos.single;

    throw const FormatException(
      'Código inválido: não foi possível identificar um único pedido.',
    );
  }

  // Retorna de uma vez o código limpo e a tabela de destino.
  static ({String codigo, DestinoLeitura destino}) analisarCodigo(
    String codigoLido,
  ) {
    final codigo = normalizarCodigo(codigoLido);
    final destino = codigo.length == 13
        ? DestinoLeitura.portalPostal
        : DestinoLeitura.pedidoDeVenda;
    return (codigo: codigo, destino: destino);
  }

  // Mantido para telas que precisem consultar somente o destino.
  static DestinoLeitura definirDestino(String codigoLido) {
    return analisarCodigo(codigoLido).destino;
  }
}
