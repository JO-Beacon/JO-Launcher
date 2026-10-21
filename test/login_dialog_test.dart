import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/auth/account.dart';
import 'package:jolauncher/auth/auth_service.dart';
import 'package:jolauncher/auth/login_dialog.dart';

import 'test_app.dart';

/// Login dialog regression: code display, successful close, failure retry/close, cancel.
void main() {
  const DeviceCodeInfo info = DeviceCodeInfo(
    userCode: 'ABCD-EFGH',
    deviceCode: 'device',
    verificationUri: 'https://microsoft.com/devicelogin',
    expiresIn: 900,
    interval: 1,
  );

  MinecraftAccount account() => MinecraftAccount(
    name: 'Steve',
    uuid: '069a79f444e94726a5befca90e38aaf5',
    refreshToken: 'r',
    accessToken: 'a',
    accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  Widget host(GlobalKey<NavigatorState> nav) {
    return testApp(
      const ColoredBox(color: Color(0xFF000000)),
      navigatorKey: nav,
    );
  }

  void size(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('shows the code, closes on success and returns the account', (
    WidgetTester t,
  ) async {
    size(t);
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final FakeAuth auth = FakeAuth(info);
    await t.pumpWidget(host(nav));

    final Future<MinecraftAccount?> pending = showMicrosoftLogin(
      nav.currentContext!,
      auth,
    );
    await t.pump();
    await t.pump();

    expect(find.text('ABCD-EFGH'), findsOneWidget);
    expect(find.text('https://microsoft.com/devicelogin'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
    expect(find.text('Open link'), findsOneWidget);
    expect(find.text('Waiting for authorization…'), findsOneWidget);

    auth.completer.complete(account());
    await t.pumpAndSettle();

    expect(await pending, isNotNull);
    expect(find.text('ABCD-EFGH'), findsNothing);
  });

  testWidgets('shows the failure reason and can be closed', (
    WidgetTester t,
  ) async {
    size(t);
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final FakeAuth auth = FakeAuth(info);
    await t.pumpWidget(host(nav));

    final Future<MinecraftAccount?> pending = showMicrosoftLogin(
      nav.currentContext!,
      auth,
    );
    await t.pump();
    await t.pump();

    auth.completer.completeError(const AuthException('auth.error.declined'));
    await t.pumpAndSettle();

    expect(
      find.text('You declined the sign-in on the authorization page.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await t.tap(find.text('Close'));
    await t.pumpAndSettle();

    expect(await pending, isNull);
    expect(
      find.text('You declined the sign-in on the authorization page.'),
      findsNothing,
    );
  });

  testWidgets('cancel closes the dialog and returns null', (
    WidgetTester t,
  ) async {
    size(t);
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    final FakeAuth auth = FakeAuth(info);
    await t.pumpWidget(host(nav));

    final Future<MinecraftAccount?> pending = showMicrosoftLogin(
      nav.currentContext!,
      auth,
    );
    await t.pump();
    await t.pump();

    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(await pending, isNull);

    // Let the pending login finish so the test does not leave a Future hanging.
    auth.completer.complete(account());
    await t.pumpAndSettle();
  });
}

class FakeAuth implements Authenticator {
  FakeAuth(this.info);

  final DeviceCodeInfo info;
  final Completer<MinecraftAccount> completer = Completer<MinecraftAccount>();

  @override
  Future<MinecraftAccount> loginWithDeviceCode({
    required void Function(DeviceCodeInfo info) onCode,
    required bool Function() isCancelled,
  }) {
    onCode(info);
    return completer.future;
  }

  @override
  Future<MinecraftAccount> refresh(MinecraftAccount account) {
    throw UnimplementedError();
  }
}
