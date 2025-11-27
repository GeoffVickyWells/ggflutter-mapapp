import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geezer_guides_flutter/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GeezerGuidesApp());

    // Verify that the app starts (will show startup screen)
    expect(find.byType(GeezerGuidesApp), findsOneWidget);
  });
}
