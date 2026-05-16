import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apid/pages_desktop/widgets/desktop_sidebar.dart';

void main() {
  testWidgets('DesktopSidebar renders and handles interactions', (WidgetTester tester) async {
    String activeView = 'POS';
    bool logoutCalled = false;
    String? navigatedView;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopSidebar(
            activeView: activeView,
            onNavigate: (view) {
              navigatedView = view;
            },
            onLogout: () {
              logoutCalled = true;
            },
            userEmail: 'sp001@apu.edu.my',
          ),
        ),
      ),
    );

    // Verify initial render
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

    // Test Navigation Tap
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(navigatedView, 'PROFILE');

    // Test Logout Tap
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(logoutCalled, isTrue);

    // Test Hover (Regression for Shadow Crash)
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    
    // Hover over Logo (assumed to be near top)
    final logoFinder = find.byIcon(Icons.store_rounded); // Default logo
    if (logoFinder.evaluate().isNotEmpty) {
        final center = tester.getCenter(logoFinder);
        await gesture.moveTo(center);
        await tester.pumpAndSettle(); // Should trigger hover enter
        
        // Move away
        await gesture.moveTo(const Offset(0, 0));
        await tester.pumpAndSettle(); // Should trigger hover exit
    }
  });
}
