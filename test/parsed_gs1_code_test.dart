import 'package:flutter_test/flutter_test.dart';
import 'package:qr_datamatrix_reader/src/models/parsed_gs1_code.dart';

void main() {
  test('separa os campos GS1 do exemplo de etiqueta', () {
    const rawValue =
        '01079087187518382407322\u001D10L2250917002-450-A'
        '\u001D921\u001D1125091793297\u001D94293\u001D95P';

    final parsed = ParsedGs1Code.tryParse(rawValue);

    expect(parsed, isNotNull);
    expect(parsed!.gtin, '07908718751838');
    expect(parsed.product, '7322');
    expect(parsed.lot, 'L2250917002-450-A');
    expect(parsed.quantity, '1');
    expect(parsed.productionDate, '250917');
    expect(parsed.boxNumber, '297');
    expect(parsed.labelQuantity, '293');
    expect(parsed.type, 'P');
  });

  test('monta o json com os nomes das colunas do banco', () {
    const rawValue =
        '01079087187518382407322\u001D10L2250917002-450-A'
        '\u001D921\u001D1125091793297\u001D94293\u001D95P';

    final parsed = ParsedGs1Code.tryParse(rawValue);

    expect(parsed!.toJsonFields(), <String, Object?>{
      'gtin': '07908718751838',
      'produto': '7322',
      'lote': 'L2250917002-450-A',
      'quantidade': '1',
      'data_fab': '250917',
      'caixa': '297',
      'qtd_etiqueta': '293',
      'tipo': 'P',
    });
  });

  test('ignora identificador de simbologia quando o leitor enviar', () {
    const rawValue = ']d201079087187518382407322\u001D10ABC';

    final parsed = ParsedGs1Code.tryParse(rawValue);

    expect(parsed!.gtin, '07908718751838');
    expect(parsed.product, '7322');
    expect(parsed.lot, 'ABC');
  });
}
