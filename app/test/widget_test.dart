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
    expect(find.text('الكسور: أجزاء متساوية'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('مقارنة كسور الوحدة'), 150);
    expect(find.text('مقارنة كسور الوحدة'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('القسمة: توزيع بالتساوي'), 150);
    expect(find.text('القسمة: توزيع بالتساوي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
