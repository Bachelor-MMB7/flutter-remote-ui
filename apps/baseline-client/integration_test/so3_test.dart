import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pyck/main.dart' as app;

// pump until the widget is gone (max ~15 s), the submit snackbar bug
Future<void> pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150 && finder.evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('SO3 series', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // set per block via --dart-define=SO3_PASSES=168
    const passes = int.fromEnvironment('SO3_PASSES', defaultValue: 2);
    for (var i = 0; i < passes; i++) {
      // tester.enterText is unreliable in profile mode on real iOS devices
      await tester.pumpAndSettle();
      final tf = tester.widget<TextField>(find.byType(TextField).first);
      tf.onChanged?.call('A-100');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // step 1: photo is optional, continue directly
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // step 2: pick a location, then continue
      await tester.tap(find.text('Picking Area B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // step 3: submit resets the workflow to step 0
      await tester.tap(find.text('Confirm Receipt'));
      await tester.pumpAndSettle();
      // let the snackbar clear, otherwise it covers buttons of the next pass
      await pumpUntilGone(tester, find.text('submitted'));
    }

    // after the last submit the app is back on step 0
    expect(find.byType(TextField), findsOneWidget);
  });
}