import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madrissti_prototype/main.dart';

void main() {
  testWidgets('Arabic catalogue loads three lessons at 200% text size', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(2)), child: const LibraryScreen()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('رياضيات الصف الرابع'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
