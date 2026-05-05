class ParsedGs1Code {
  const ParsedGs1Code({
    required this.rawValue,
    this.gtin,
    this.product,
    this.lot,
    this.quantity,
    this.productionDate,
    this.boxNumber,
    this.labelQuantity,
    this.type,
  });

  static ParsedGs1Code? tryParse(String rawValue) {
    final fields = _parseFields(_normalizeRawValue(rawValue));
    final parsedCode = ParsedGs1Code(
      rawValue: rawValue,
      gtin: fields['01'],
      product: fields['240'],
      lot: fields['10'],
      quantity: fields['92'],
      productionDate: fields['11'],
      boxNumber: fields['93'],
      labelQuantity: fields['94'],
      type: fields['95'],
    );

    return parsedCode.hasKnownFields ? parsedCode : null;
  }

  final String rawValue;
  final String? gtin;
  final String? product;
  final String? lot;
  final String? quantity;
  final String? productionDate;
  final String? boxNumber;
  final String? labelQuantity;
  final String? type;

  bool get hasKnownFields => displayFields.isNotEmpty;

  List<ParsedGs1Field> get displayFields {
    return <ParsedGs1Field>[
      if (_hasValue(gtin)) ParsedGs1Field('GTIN', gtin!),
      if (_hasValue(product)) ParsedGs1Field('Produto', product!),
      if (_hasValue(lot)) ParsedGs1Field('Lote', lot!),
      if (_hasValue(quantity)) ParsedGs1Field('Quantidade', quantity!),
      if (_hasValue(productionDate))
        ParsedGs1Field('Data Fab', productionDate!),
      if (_hasValue(boxNumber)) ParsedGs1Field('Caixa', boxNumber!),
      if (_hasValue(labelQuantity))
        ParsedGs1Field('Qtd Etiqueta', labelQuantity!),
      if (_hasValue(type)) ParsedGs1Field('Tipo', type!),
    ];
  }

  Map<String, Object?> toJsonFields() {
    return <String, Object?>{
      if (_hasValue(gtin)) 'gtin': gtin,
      if (_hasValue(product)) 'produto': product,
      if (_hasValue(lot)) 'lote': lot,
      if (_hasValue(quantity)) 'quantidade': quantity,
      if (_hasValue(productionDate)) 'data_fab': productionDate,
      if (_hasValue(boxNumber)) 'caixa': boxNumber,
      if (_hasValue(labelQuantity)) 'qtd_etiqueta': labelQuantity,
      if (_hasValue(type)) 'tipo': type,
    };
  }
}

class ParsedGs1Field {
  const ParsedGs1Field(this.label, this.value);

  final String label;
  final String value;
}

String visibleGs1Value(String rawValue) {
  return rawValue.replaceAll(_groupSeparator, ' <GS> ');
}

const _groupSeparator = '\u001D';

const _definitions = <_Gs1AiDefinition>[
  _Gs1AiDefinition('240', maxLength: 30),
  _Gs1AiDefinition('01', fixedLength: 14),
  _Gs1AiDefinition('10', maxLength: 20),
  _Gs1AiDefinition('11', fixedLength: 6),
  _Gs1AiDefinition('92', maxLength: 90),
  _Gs1AiDefinition('93', maxLength: 90),
  _Gs1AiDefinition('94', maxLength: 90),
  _Gs1AiDefinition('95', maxLength: 90),
];

Map<String, String> _parseFields(String value) {
  final fields = <String, String>{};
  var index = 0;

  while (index < value.length) {
    if (value[index] == _groupSeparator) {
      index++;
      continue;
    }

    final definition = _definitionAt(value, index);
    if (definition == null) {
      return fields;
    }

    index += definition.ai.length;
    final fieldValue = definition.fixedLength == null
        ? _readVariableValue(value, index, definition.maxLength!)
        : _readFixedValue(value, index, definition.fixedLength!);

    if (fieldValue == null) {
      return fields;
    }

    if (fieldValue.value.trim().isNotEmpty) {
      fields[definition.ai] = fieldValue.value;
    }

    index = fieldValue.nextIndex;
  }

  return fields;
}

_Gs1AiDefinition? _definitionAt(String value, int index) {
  for (final definition in _definitions) {
    if (value.startsWith(definition.ai, index)) {
      return definition;
    }
  }

  return null;
}

_ParsedFieldValue? _readFixedValue(String value, int index, int length) {
  final end = index + length;
  if (end > value.length) {
    return null;
  }

  return _ParsedFieldValue(value.substring(index, end), end);
}

_ParsedFieldValue _readVariableValue(String value, int index, int maxLength) {
  final nextSeparator = value.indexOf(_groupSeparator, index);
  final end = nextSeparator == -1 ? value.length : nextSeparator;
  final fieldValue = value.substring(index, end);

  return _ParsedFieldValue(
    fieldValue.length > maxLength
        ? fieldValue.substring(0, maxLength)
        : fieldValue,
    nextSeparator == -1 ? value.length : nextSeparator + 1,
  );
}

String _normalizeRawValue(String rawValue) {
  final trimmedValue = rawValue.trim();
  final withoutSymbologyIdentifier =
      trimmedValue.startsWith(']') && trimmedValue.length > 3
      ? trimmedValue.substring(3)
      : trimmedValue;

  return withoutSymbologyIdentifier
      .replaceAll(r'\u001d', _groupSeparator)
      .replaceAll(r'\u001D', _groupSeparator)
      .replaceAll(r'\x1d', _groupSeparator)
      .replaceAll(r'\x1D', _groupSeparator);
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}

class _Gs1AiDefinition {
  const _Gs1AiDefinition(this.ai, {this.fixedLength, this.maxLength});

  final String ai;
  final int? fixedLength;
  final int? maxLength;
}

class _ParsedFieldValue {
  const _ParsedFieldValue(this.value, this.nextIndex);

  final String value;
  final int nextIndex;
}
