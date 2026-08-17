enum DestinoLeitura { portalPostal, pedidoDeVenda }

class Regras {
  const Regras._();

  // Chame esta função assim que o scanner entregar o código lido.
  static DestinoLeitura definirDestino(String codigoLido) {
    final codigo = codigoLido.trim();
    if (codigo.isEmpty) {
      throw const FormatException('O scanner não retornou um código válido.');
    }

    final possuiTamanhoPostal = codigo.length == 13 || codigo.length == 14;
    final terminaComBr = codigo.toUpperCase().endsWith('BR');

    // Para o Portal Postal, as duas condições devem ser verdadeiras.
    return possuiTamanhoPostal && terminaComBr
        ? DestinoLeitura.portalPostal
        : DestinoLeitura.pedidoDeVenda;
  }
}
