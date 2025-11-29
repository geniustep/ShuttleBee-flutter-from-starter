import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter_starter/shared/widgets/buttons/primary_button.dart';

void main() {
  testWidgets('PrimaryButton renders correctly', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Test Button',
            onPressed: () {},
          ),
        ),
      ),
    );

    // Verify button text
    expect(find.text('Test Button'), findsOneWidget);
  });

  testWidgets('PrimaryButton calls onPressed when tapped',
      (WidgetTester tester) async {
    var pressed = false;

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Test Button',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    // Tap button
    await tester.tap(find.text('Test Button'));
    await tester.pump();

    // Verify callback was called
    expect(pressed, true);
  });
}
