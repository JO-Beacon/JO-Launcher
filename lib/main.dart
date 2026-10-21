import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app.dart';
import 'auth/account_store.dart';
import 'privacy/privacy_store.dart';
import 'theme/settings_store.dart';

/// Adds this application's own license to Flutter's license registry.
/// Otherwise the license page only lists third-party dependencies.
void _registerOwnLicense() {
  LicenseRegistry.addLicense(() async* {
    final String text = await rootBundle.loadString('LICENSE');
    yield LicenseEntryWithLineBreaks(<String>['JO-Launcher'], text);
  });
}

/// Adds the bundled third-party license texts to the registry so they can be
/// viewed without opening the installation directory.
void _registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    final String text = await rootBundle.loadString(
      'assets/licenses/RemixIcon-License-1.0.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Remix Icon'], text);
  });
  for (final String name in <String>['Noto Sans SC']) {
    LicenseRegistry.addLicense(() async* {
      final String text = await rootBundle.loadString(
        'assets/licenses/SourceHanSans-OFL-1.1.txt',
      );
      yield LicenseEntryWithLineBreaks(<String>[name], text);
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerOwnLicense();
  _registerBundledLicenses();
  final SettingsStore store = await SettingsStore.open();
  final AccountStore accounts = await AccountStore.open();
  final PrivacyStore privacy = await PrivacyStore.open();
  runApp(
    LauncherApp(
      store: store,
      initial: store.load(),
      initialRailWidth: store.loadRailW(),
      initialGameDir: store.loadGameDir(),
      initialCurrentVersion: store.loadCurrentVersion(),
      initialAccount: await accounts.load(),
      accountStore: accounts,
      privacyStore: privacy,
    ),
  );
}
