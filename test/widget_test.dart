import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveslive/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WavesLiveApp(),
      ),
    );
    // Just verify it doesn't throw
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
