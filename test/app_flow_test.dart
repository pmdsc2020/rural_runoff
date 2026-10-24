// test/app_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rural_runoff/features/catchment/screens/result_screen.dart';
import 'package:rural_runoff/main.dart';

void main() {
  testWidgets('Inputs drive the live preview and open the results screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: RuralRunoffApp()));
    await tester.pumpAndSettle();

    expect(find.text('— m³/s'), findsOneWidget);

    Future<void> enter(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await enter('Area (A)', '2');
    await enter('Longest flow length (L)', '1500');
    await enter('Elevation drop (ΔH)', '20');
    await enter('C (0.01 – 1.00)', '0.4');
    await enter('Rainfall intensity (I)', '50');
    await tester.pumpAndSettle();

    // Q = 0.4 * 50 * 2 / 3.6
    expect(find.text('11.111 m³/s'), findsOneWidget);

    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('11.111  m³/s', findRichText: true), findsOneWidget);
    expect(find.text('Design hydrograph'), findsOneWidget);
  });
}
