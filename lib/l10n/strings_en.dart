// English (base table).
//
// Key naming: `<area>.<name>`. Placeholders use `{name}` and are replaced by
// `AppLocalizations.t`. Every other language table must contain the same keys
// (`test/localization_test.dart` enforces it).

const Map<String, String> stringsEn = <String, String>{
  // Common
  'common.cancel': 'Cancel',
  'common.close': 'Close',
  'common.retry': 'Retry',
  'common.back': 'Back',
  'common.save': 'Save',
  'common.saving': 'Saving…',
  'common.saved': 'Saved.',
  'common.login': 'Sign in',
  'common.logout': 'Sign out',
  'common.delete': 'Delete',
  'common.change': 'Change',
  'common.view': 'View',
  'common.openFolder': 'Open folder',
  'common.notYet': 'Not available yet',
  'common.auto': 'Automatic',
  'common.manual': 'Manual',
  'common.enabled': 'Enabled',
  'common.disabled': 'Disabled',
  'common.keyPress': 'Press a key combination…',
  'common.keyUnset': 'Not set',
  'common.loading': 'Loading…',
  'common.listSeparator': ', ',

  // Navigation and rail
  'nav.launch': 'Launch',
  'nav.version': 'Version settings',
  'nav.settings': 'Settings',
  'rail.microsoftLogin': 'Microsoft sign-in',

  // Privacy
  'privacy.title': 'Privacy',
  'privacy.hint': 'How local account data is handled',
  'privacy.summary':
      'JO-Launcher processes your Microsoft account name, Minecraft player '
      'name and UUID, login tokens (access and refresh tokens), and profile / '
      'skin data on this device.\n\n'
      'The data is stored only in a local file protected by Windows DPAPI '
      '(via flutter_secure_storage) and is used to sign in, renew the '
      'session and launch the game. It is not uploaded to JO-Launcher '
      'servers, and the app has no telemetry.\n\n'
      'During sign-in, data is sent to Microsoft, Xbox and Minecraft services '
      'under their privacy policies.\n\n'
      'You can delete this data at any time in Settings → Account → Delete '
      'account and local data.',
  'privacy.agree': 'Agree and continue',
  'privacy.fullNotice': 'Open full privacy notice',
  'privacy.linkError': 'Could not open the privacy notice.',

  // Launch page
  'launch.title': 'Launch',
  'launch.subtitle': 'Current version and running instances',
  'launch.rescan': 'Rescan',
  'launch.scanError': 'Could not read the game directory: {error}',
  'launch.noVersionsDir': 'There is no versions folder in this directory.',
  'launch.noVersions': 'No launchable versions yet.',
  'launch.chooseVersion': 'Choose a version to launch',
  'launch.versionCount': 'This directory contains {count} versions.',
  'launch.switch': 'Switch',
  'launch.collapse': 'Collapse',
  'launch.launchGame': 'Launch game',
  'launch.notImplemented': 'Launching is not implemented yet.',
  'launch.running': 'Running',
  'launch.noneRunning': 'No games are running.',
  'launch.broken': '{count} more folders have no readable manifest: {names}',

  // Version settings
  'version.title': 'Version settings',
  'version.current': 'Current version',
  'version.reload': 'Reload',
  'version.pickFirst': 'Choose a version on the Launch page first.',
  'version.goLaunch': 'Go to Launch',
  'version.versionSection': 'Version',
  'version.name': 'Name',
  'version.gameVersion': 'Game version',
  'version.loader': 'Loader',
  'version.directory': 'Directory',
  'version.javaSection': 'Java',
  'version.javaSource': 'Source',
  'version.javaAutoHint': 'Automatic = detect at launch',
  'version.javaPathHint': 'Full path to java.exe / javaw.exe',
  'version.memorySection': 'Memory',
  'version.memoryMin': 'Minimum',
  'version.memoryMax': 'Maximum',
  'version.memoryHint': 'MB, empty = automatic',
  'version.jvmSection': 'JVM arguments',
  'version.jvmHint': 'e.g. -XX:+UseG1GC, empty = none',
  'version.errorRead': 'Could not read version settings: {error}',
  'version.errorOpenFolder': 'Could not open the folder.',
  'version.errorMemoryNumber':
      'Memory must be a positive integer, or left empty.',
  'version.errorMemoryPositive': 'Memory must be greater than 0.',
  'version.errorMemoryOrder': 'Minimum memory cannot exceed maximum memory.',
  'version.errorWrite': 'Could not write jolauncher.json: {error}',

  // Settings
  'settings.title': 'Settings',
  'settings.subtitle': 'Appearance, directory and about',
  'settings.sectionLanguage': 'Language',
  'settings.language': 'Display language',
  'settings.languageSystem': 'Follow system',
  'settings.sectionAppearance': 'Appearance',
  'settings.dark': 'Dark',
  'settings.light': 'Light',
  'settings.darkHint': 'Following the system; this setting has no effect',
  'settings.followSystem': 'Follow system',
  'settings.followSystemHint': 'Follow the system appearance setting',
  'settings.sectionGameDir': 'Game directory',
  'settings.currentDir': 'Current directory',
  'settings.sectionAccount': 'Account',
  'settings.microsoftAccount': 'Microsoft account',
  'settings.loginToPlay': 'Sign in to launch the game',
  'settings.characterName': 'Player name',
  'settings.loginStatus': 'Sign-in status',
  'settings.autoRenew': 'Tokens renew automatically when they expire',
  'settings.deleteAccount': 'Delete account and local data',
  'settings.deleteAccountHint':
      'Remove the account, tokens and cached profile from this device.',
  'settings.deleteAccountTitle': 'Delete account and local data?',
  'settings.deleteAccountMessage':
      'This removes the signed-in account, access token, refresh token and '
      'cached profile from this device. Game files and version settings are '
      'not deleted. This cannot be undone.',
  'settings.deleteAccountError': 'Could not delete local account data: {error}',
  'settings.sectionAbout': 'About',
  'settings.version': 'Version',
  'settings.licenses': 'Licenses',
  'settings.licensesHint': 'This app and third-party components',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH '
      'MOJANG OR MICROSOFT.',
  'settings.versionReadError': 'Could not read',
  'settings.pickerError': 'Could not open the folder picker: {error}',

  // Microsoft sign-in
  'auth.title': 'Microsoft sign-in',
  'auth.requesting': 'Requesting a sign-in code…',
  'auth.instructions':
      'Open the link below in your browser and enter the code:',
  'auth.copyCode': 'Copy code',
  'auth.openLink': 'Open link',
  'auth.waiting': 'Waiting for authorization…',
  'auth.copied': 'Code copied.',
  'auth.openBrowserFailed':
      'Could not open the browser; please copy the link manually.',
  'auth.errorGeneric': 'Sign-in failed: {error}',
  'auth.error.noClientId':
      'This build has no Microsoft client_id configured; sign-in is '
      'unavailable. Set the JO_MS_CLIENT_ID environment variable or pass '
      '--dart-define=JO_MS_CLIENT_ID=... at build time.',
  'auth.error.timeout': 'Sign-in timed out; please try again.',
  'auth.error.declined': 'You declined the sign-in on the authorization page.',
  'auth.error.codeExpired': 'The sign-in code expired; please try again.',
  'auth.error.codeInvalid': 'The sign-in code is invalid; please try again.',
  'auth.error.deviceCode': 'Could not request a sign-in code: {detail}',
  'auth.error.deviceCodeIncomplete':
      'The sign-in code response was incomplete; please try again.',
  'auth.error.tokenIncomplete':
      'The token response was incomplete; please try again.',
  'auth.error.ms': 'Microsoft sign-in failed: {detail}',
  'auth.error.xbox': 'Xbox Live sign-in failed: {detail}',
  'auth.error.xsts': 'Xbox authorization failed: {detail}',
  'auth.error.xboxRejected':
      'Xbox authorization was rejected; check the account status.',
  'auth.error.xboxNoProfile':
      'This Microsoft account has no Xbox profile yet. Sign in once at '
      'xbox.com and try again.',
  'auth.error.xboxRegion': 'Xbox Live is not available in this region.',
  'auth.error.xboxChild':
      'This is a child account; add it to a Microsoft family first.',
  'auth.error.xboxCode': 'Xbox authorization failed (XErr {xerr}).',
  'auth.error.whitelist':
      'Mojang has not added JO-Launcher to the application allowlist yet '
      '(Invalid app registration); this step cannot proceed.',
  'auth.error.minecraftRejected': 'Minecraft sign-in was rejected: {detail}',
  'auth.error.minecraft': 'Minecraft sign-in failed: {detail}',
  'auth.error.minecraftTokenIncomplete':
      'The Minecraft token response was incomplete; please try again.',
  'auth.error.noJavaEdition':
      'This Microsoft account does not own Minecraft: Java Edition.',
  'auth.error.profile': 'Could not read the player profile: {detail}',
  'auth.error.profileIncomplete':
      'The player profile was incomplete; please try again.',
  'auth.error.refreshExpired': 'The session expired; please sign in again.',
  'auth.error.refresh': 'Could not renew the session: {detail}',
  'auth.error.refreshIncomplete':
      'The renewal response was incomplete; please sign in again.',

  // Licenses
  'licenses.title': 'Licenses',
  'licenses.count': '{count} entries',
  'licenses.loading': 'Reading the license list…',
  'licenses.viewText': 'View text →',
  'licenses.unsigned': '(Unattributed)',
  'licenses.noText': '(No license text provided)',

  // Launch errors
  'launch.error.manifestMissing': 'Version manifest not found: {name}',
  'launch.error.manifestRead':
      'Could not read the version manifest for {name}: {error}',
  'launch.error.inheritCycle': 'Version inheritance loop: {name}',
  'launch.error.javaPath': 'Not a usable Java executable: {path}',
  'launch.error.noJava':
      'No Java runtime found. Set the Java path in version settings.',
  'launch.error.javaTooOld':
      'This version requires Java {required}, but Java {found} was found.',
  'launch.error.missingClient': 'Client jar is missing: {path}',
  'launch.error.missingLibrary': 'Library file is missing: {path}',
  'launch.error.missingAssetsIndex':
      'This version manifest has no asset index.',
  'launch.error.missingAssets': 'Asset index is missing: {path}',
  'launch.error.noMainClass': 'This version manifest has no main class.',
  'launch.error.natives': 'Could not extract natives: {error}',
  'launch.error.start': 'Could not start the game: {error}',
  'launch.error.alreadyRunning': 'This version is already running.',
  'launch.loginRequired': 'Sign in to launch the game.',
  'launch.starting': 'Starting…',
  'launch.log': 'Log',
  'launch.stop': 'Stop',
  'launch.logTitle': 'Game log · {name}',

  // Loaders
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
