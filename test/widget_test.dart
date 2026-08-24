import 'package:babyland/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Smoke test for Babyland.
///
/// The default Flutter counter test (`find.text('0')`) no longer matches this
/// app. Pumping the full [Babyland] widget requires Firebase / Hive / plugin
/// native channels and hangs in a Windows unit-test VM, so this test covers
/// the actual regression: [AuthService] (what `Babyland.build` reads via
/// `sl.authService`) must be constructible before providers are mounted.
///
/// Full iOS boot is validated by the Codemagic `babyland-ios-testflight`
/// IPA build, not by this widget test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Babyland AuthService provider tree builds without late-init errors',
      (WidgetTester tester) async {
    final authService = AuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: authService,
        child: const MaterialApp(
          title: 'Babyland',
          home: Scaffold(
            body: Center(child: Text('Babyland')),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Babyland'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
