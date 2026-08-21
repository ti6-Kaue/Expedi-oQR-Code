enum DestinoLeitura { portalPostal, pedidoDeVenda }

extension RotuloDoDestino on DestinoLeitura {
  String get rotulo => this == DestinoLeitura.portalPostal
      ? 'Portal Postal'
      : 'Pedido de Venda';

  // Chave enviada ao backend no campo "modo".
  String get chave => this == DestinoLeitura.portalPostal
      ? 'portalPostal'
      : 'pedidoDeVenda';
}

/// Erro lançado quando o código lido não pertence ao modo escolhido.
class CodigoDeOutroModo implements Exception {
  const CodigoDeOutroModo(this.destinoDetectado);

  final DestinoLeitura destinoDetectado;

  @override
  String toString() =>
      'Este código é de ${destinoDetectado.rotulo}. Abra o modo ${destinoDetectado.rotulo}.';
}

class Regras {
  const Regras._();

  // REGRA: LIMPEZA DO CÓDIGO
  // Remove caracteres invisíveis e extrai o número do pedido quando o código
  // da câmera vier com prefixos, como ocorre em alguns Data Matrix.
  static String normalizarCodigo(String codigoLido) {
    final semControles = codigoLido
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .trim();

    // Alguns leitores acrescentam o identificador AIM "]d2" ao Data Matrix.
    final codigo = semControles.replaceFirst(RegExp(r'^\][A-Za-z]\d'), '');

    // REGRA: PORTAL POSTAL
    // Somente um código com exatamente 13 caracteres e final BR é aceito.
    final codigoPostal =
        codigo.length == 13 && codigo.toUpperCase().endsWith('BR');
    if (codigoPostal) return codigo;

    // REGRA: PEDIDO DE VENDA
    // Aceita um único grupo numérico com 5 ou 6 dígitos.
    final gruposNumericos = RegExp(r'\d+')
        .allMatches(codigo)
        .map((resultado) => resultado.group(0)!)
        .where((numero) => numero.length == 5 || numero.length == 6)
        .toList();

    // REGRA: EVITAR PEDIDO ERRADO
    // Se houver nenhum ou mais de um número possível, ignora a leitura.
    if (gruposNumericos.length == 1) return gruposNumericos.single;

    throw const FormatException();
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

  // Normaliza o código e garante que ele pertence ao modo escolhido pelo botão.
  static ({String codigo, DestinoLeitura destino}) analisarCodigoNoModo(
    String codigoLido,
    DestinoLeitura modoEscolhido,
  ) {
    final leitura = analisarCodigo(codigoLido);
    if (leitura.destino != modoEscolhido) {
      throw CodigoDeOutroModo(leitura.destino);
    }
    return leitura;
  }
}
