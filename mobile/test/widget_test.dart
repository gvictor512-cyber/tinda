// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:roommatematch/main.dart';

void main() {
  testWidgets('App splash smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoomMateMatchApp());

    // Wait for the splash animation to complete.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Verify that the splash screen title is shown.
    expect(find.text('RoomMate Match'), findsOneWidget);
  });
}
