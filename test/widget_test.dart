import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qr_datamatrix_reader/src/app/qr_datamatrix_app.dart';

void main() {
  testWidgets('mostra a tela inicial do scanner', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const QrDataMatrixApp());
    await tester.pump();

    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    expect(find.text('Scanner pronto'), findsOneWidget);
    expect(find.text('Nada lido ainda.'), findsOneWidget);
  });
}
