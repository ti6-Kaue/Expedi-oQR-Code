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

  // Chame esta função assim que o scanner entregar o código lido.
  static DestinoLeitura definirDestino(String codigoLido) {
    final codigo = normalizarCodigo(codigoLido);
    if (codigo.isEmpty) {
      throw const FormatException('O scanner não retornou um código válido.');
    }

    final possuiTamanhoPostal = codigo.length == 13;
    final terminaComBr = codigo.toUpperCase().endsWith('BR');

    // Para o Portal Postal, as duas condições devem ser verdadeiras.
    if (possuiTamanhoPostal && terminaComBr) {
      return DestinoLeitura.portalPostal;
    }

    // Para Pedido de Venda, aceite somente números com 5 ou 6 dígitos.
    if (RegExp(r'^\d{5,6}$').hasMatch(codigo)) {
      return DestinoLeitura.pedidoDeVenda;
    }

    throw const FormatException(
      'Código inválido: use 13 caracteres terminando em BR ou 5 a 6 dígitos.',
    );
  }
}
