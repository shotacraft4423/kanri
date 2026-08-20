import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kanri/main.dart';

void main() {
  testWidgets('App starts and shows the lock screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KanriApp());
    await tester.pump();

    expect(find.byIcon(Icons.lock), findsOneWidget);
  });
}
