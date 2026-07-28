import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/main.dart';

void main() {
  testWidgets('Centim arrenca dins del ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(MaterialApp), findsOneWidget);

    // Desmunta l'Splash i deixa completar el seu Future.delayed sense navegar.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
