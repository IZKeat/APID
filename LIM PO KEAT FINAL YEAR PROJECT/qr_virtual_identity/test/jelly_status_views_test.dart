import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apid/widgets/jelly_status_views.dart';

void main() {
  group('JellyStatusViews Tests', () {
    testWidgets('JellySuccessView renders message and button', (WidgetTester tester) async {
      bool donePressed = false;

      await tester.pumpWidget(MaterialApp(
        home: JellySuccessView(
          message: 'Login Successful',
          data: const {'email': 'test@example.com'},
          onDone: () => donePressed = true,
        ),
      ));

      // Verify message
      expect(find.text('Login Successful'), findsOneWidget);
      expect(find.text('email: '), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Verify button
      expect(find.text('Done'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(donePressed, isTrue);
    });

    testWidgets('JellyErrorView renders error and retry button', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: JellyErrorView(
          errorMessage: 'Network Error',
          onRetry: () => retryPressed = true,
        ),
      ));

      // Verify error message
      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Oops!'), findsOneWidget);

      // Verify button
      expect(find.text('Try Again'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryPressed, isTrue);
    });

    testWidgets('JellyProcessingView renders loading text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: JellyProcessingView()),
      ));

      // Pump a few frames to let initial animations start, but don't wait for completion (infinite)
      await tester.pump(const Duration(milliseconds: 500));

      // Verify text
      expect(find.text('Processing...'), findsOneWidget);
      expect(find.text('Verifying secure data'), findsOneWidget);
    });
  });
}
