import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/privacy/privacy_dialog.dart';
import 'package:jolauncher/privacy/privacy_store.dart';
import 'package:jolauncher/ui/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

void main() {
  testWidgets('privacy dialog appears once and records device consent', (
    WidgetTester t,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PrivacyStore store = PrivacyStore(prefs);
    bool? result;

    await t.pumpWidget(
      testApp(
        Builder(
          builder: (BuildContext context) => LauncherButton(
            text: 'open',
            onTap: () async {
              result = await ensurePrivacyConsent(context, store);
            },
          ),
        ),
        locale: const Locale('en'),
      ),
    );

    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Agree and continue'), findsOneWidget);
    expect(store.accepted, isFalse);

    await t.tap(find.text('Agree and continue'));
    await t.pumpAndSettle();

    expect(result, isTrue);
    expect(store.accepted, isTrue);
  });
}
