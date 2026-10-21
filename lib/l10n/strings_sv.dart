// Swedish (svenska).
//
// Key naming: `<area>.<name>`. Placeholders use `{name}` and are replaced by
// `AppLocalizations.t`. Keep this table in sync with stringsEn.dart.

const Map<String, String> stringsSv = <String, String>{
  // Common
  'common.cancel': 'Avbryt',
  'common.close': 'Stäng',
  'common.retry': 'Försök igen',
  'common.back': 'Tillbaka',
  'common.save': 'Spara',
  'common.saving': 'Sparar…',
  'common.saved': 'Sparat.',
  'common.login': 'Logga in',
  'common.logout': 'Logga ut',
  'common.delete': 'Radera',
  'common.change': 'Ändra',
  'common.view': 'Visa',
  'common.openFolder': 'Öppna mapp',
  'common.notYet': 'Inte tillgängligt än',
  'common.auto': 'Automatiskt',
  'common.manual': 'Manuellt',
  'common.enabled': 'Aktiverat',
  'common.disabled': 'Inaktiverat',
  'common.keyPress': 'Tryck på en tangentkombination…',
  'common.keyUnset': 'Inte inställt',
  'common.loading': 'Laddar…',
  'common.listSeparator': ', ',

  // Navigation and rail
  'nav.launch': 'Starta',
  'nav.version': 'Versionsinställningar',
  'nav.settings': 'Inställningar',
  'rail.microsoftLogin': 'Microsoft-inloggning',

  // Privacy
  'privacy.title': 'Integritet',
  'privacy.hint': 'Hur lokala kontodata hanteras',
  'privacy.summary':
      'JO-Launcher behandlar ditt Microsoft-kontonamn, ditt Minecraft-spelarnamn '
      'och UUID, inloggningstoken (access- och refresh-token) samt profil-/'
      'huddata på den här enheten.\n\n'
      'Uppgifterna lagras endast i en lokal fil som skyddas av Windows DPAPI '
      '(via flutter_secure_storage) och används för att logga in, förnya '
      'sessionen och starta spelet. De laddas inte upp till '
      'JO-Launcher-servrar och appen har ingen telemetri.\n\n'
      'Vid inloggning skickas data till Microsoft-, Xbox- och Minecraft-'
      'tjänster enligt deras integritetspolicyer.\n\n'
      'Du kan när som helst radera uppgifterna i Inställningar → Konto → '
      'Radera konto och lokala data.',
  'privacy.agree': 'Godkänn och fortsätt',
  'privacy.fullNotice': 'Öppna fullständig integritetsinformation',
  'privacy.linkError': 'Kunde inte öppna integritetsinformationen.',

  // Launch page
  'launch.title': 'Starta',
  'launch.subtitle': 'Aktuell version och körande instanser',
  'launch.rescan': 'Skanna igen',
  'launch.scanError': 'Kunde inte läsa spelmappen: {error}',
  'launch.noVersionsDir': 'Det finns ingen versionsmapp i den här mappen.',
  'launch.noVersions': 'Inga startbara versioner än.',
  'launch.chooseVersion': 'Välj en version att starta',
  'launch.versionCount': 'Den här mappen innehåller {count} versioner.',
  'launch.switch': 'Byt',
  'launch.collapse': 'Fäll ihop',
  'launch.launchGame': 'Starta spelet',
  'launch.notImplemented': 'Start är inte implementerat än.',
  'launch.running': 'Körs',
  'launch.noneRunning': 'Inga spel körs.',
  'launch.broken': '{count} fler mappar saknar läsbar manifestfil: {names}',

  // Version settings
  'version.title': 'Versionsinställningar',
  'version.current': 'Aktuell version',
  'version.reload': 'Ladda om',
  'version.pickFirst': 'Välj en version på startskärmen först.',
  'version.goLaunch': 'Gå till Starta',
  'version.versionSection': 'Version',
  'version.name': 'Namn',
  'version.gameVersion': 'Spelversion',
  'version.loader': 'Loader',
  'version.directory': 'Mapp',
  'version.javaSection': 'Java',
  'version.javaSource': 'Källa',
  'version.javaAutoHint': 'Automatiskt = identifieras vid start',
  'version.javaPathHint': 'Fullständig sökväg till java.exe / javaw.exe',
  'version.memorySection': 'Minne',
  'version.memoryMin': 'Minsta',
  'version.memoryMax': 'Högsta',
  'version.memoryHint': 'MB, tomt = automatiskt',
  'version.jvmSection': 'JVM-argument',
  'version.jvmHint': 't.ex. -XX:+UseG1GC, tomt = inga',
  'version.errorRead': 'Kunde inte läsa versionsinställningarna: {error}',
  'version.errorOpenFolder': 'Kunde inte öppna mappen.',
  'version.errorMemoryNumber':
      'Minne måste vara ett positivt heltal eller lämnas tomt.',
  'version.errorMemoryPositive': 'Minne måste vara större än 0.',
  'version.errorMemoryOrder': 'Minsta minne får inte överstiga högsta minne.',
  'version.errorWrite': 'Kunde inte skriva jolauncher.json: {error}',

  // Settings
  'settings.title': 'Inställningar',
  'settings.subtitle': 'Utseende, mapp och om',
  'settings.sectionLanguage': 'Språk',
  'settings.language': 'Visningsspråk',
  'settings.languageSystem': 'Följ systemet',
  'settings.sectionAppearance': 'Utseende',
  'settings.dark': 'Mörkt',
  'settings.light': 'Ljust',
  'settings.darkHint': 'Följer systemet; inställningen har ingen effekt',
  'settings.followSystem': 'Följ systemet',
  'settings.followSystemHint': 'Följ systemets utseendeinställning',
  'settings.sectionGameDir': 'Spelmapp',
  'settings.currentDir': 'Aktuell mapp',
  'settings.sectionAccount': 'Konto',
  'settings.microsoftAccount': 'Microsoft-konto',
  'settings.loginToPlay': 'Logga in för att starta spelet',
  'settings.characterName': 'Spelarnamn',
  'settings.loginStatus': 'Inloggningsstatus',
  'settings.autoRenew': 'Token förnyas automatiskt när de går ut',
  'settings.deleteAccount': 'Radera konto och lokala data',
  'settings.deleteAccountHint':
      'Ta bort kontot, token och den cachade profilen från den här enheten.',
  'settings.deleteAccountTitle': 'Radera konto och lokala data?',
  'settings.deleteAccountMessage':
      'Detta tar bort det inloggade kontot, access-token, refresh-token och '
      'den cachade profilen från den här enheten. Spelfiler och '
      'versionsinställningar raderas inte. Detta kan inte ångras.',
  'settings.deleteAccountError': 'Kunde inte radera lokala kontodata: {error}',
  'settings.sectionAbout': 'Om',
  'settings.version': 'Version',
  'settings.licenses': 'Licenser',
  'settings.licensesHint': 'Den här appen och tredjepartskomponenter',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'INTE EN OFFICIELL MINECRAFT-PRODUKT. INTE GODKÄND AV ELLER ASSOCIERAD '
      'MED MOJANG ELLER MICROSOFT.',
  'settings.versionReadError': 'Kunde inte läsa',
  'settings.pickerError': 'Kunde inte öppna mappväljaren: {error}',

  // Microsoft sign-in
  'auth.title': 'Microsoft-inloggning',
  'auth.requesting': 'Begär en inloggningskod…',
  'auth.instructions': 'Öppna länken nedan i webbläsaren och ange koden:',
  'auth.copyCode': 'Kopiera kod',
  'auth.openLink': 'Öppna länk',
  'auth.waiting': 'Väntar på auktorisering…',
  'auth.copied': 'Koden kopierad.',
  'auth.openBrowserFailed':
      'Kunde inte öppna webbläsaren; kopiera länken manuellt.',
  'auth.errorGeneric': 'Inloggningen misslyckades: {error}',
  'auth.error.noClientId':
      'Den här versionen har inget Microsoft client_id konfigurerat; '
      'inloggning är otillgänglig. Ange miljövariabeln JO_MS_CLIENT_ID eller '
      'skicka --dart-define=JO_MS_CLIENT_ID=... vid bygget.',
  'auth.error.timeout': 'Inloggningen tog för lång tid; försök igen.',
  'auth.error.declined': 'Du avböjde inloggningen på auktoriseringssidan.',
  'auth.error.codeExpired': 'Inloggningskoden har gått ut; försök igen.',
  'auth.error.codeInvalid': 'Inloggningskoden är ogiltig; försök igen.',
  'auth.error.deviceCode': 'Kunde inte begära en inloggningskod: {detail}',
  'auth.error.deviceCodeIncomplete':
      'Svaret med inloggningskoden var ofullständigt; försök igen.',
  'auth.error.tokenIncomplete': 'Tokensvaret var ofullständigt; försök igen.',
  'auth.error.ms': 'Microsoft-inloggningen misslyckades: {detail}',
  'auth.error.xbox': 'Xbox Live-inloggningen misslyckades: {detail}',
  'auth.error.xsts': 'Xbox-auktoriseringen misslyckades: {detail}',
  'auth.error.xboxRejected':
      'Xbox-auktoriseringen avvisades; kontrollera kontostatusen.',
  'auth.error.xboxNoProfile':
      'Det här Microsoft-kontot har ingen Xbox-profil än. Logga in en gång '
      'på xbox.com och försök igen.',
  'auth.error.xboxRegion': 'Xbox Live är inte tillgängligt i den här regionen.',
  'auth.error.xboxChild':
      'Det här är ett barnkonto; lägg till det i en Microsoft-familj först.',
  'auth.error.xboxCode': 'Xbox-auktoriseringen misslyckades (XErr {xerr}).',
  'auth.error.whitelist':
      'Mojang har ännu inte lagt till JO-Launcher i programmets '
      'tillåtelselista (Invalid app registration); det här steget kan inte '
      'fortsätta.',
  'auth.error.minecraftRejected': 'Minecraft-inloggningen avvisades: {detail}',
  'auth.error.minecraft': 'Minecraft-inloggningen misslyckades: {detail}',
  'auth.error.minecraftTokenIncomplete':
      'Minecraft-tokensvaret var ofullständigt; försök igen.',
  'auth.error.noJavaEdition':
      'Det här Microsoft-kontot äger inte Minecraft: Java Edition.',
  'auth.error.profile': 'Kunde inte läsa spelarprofilen: {detail}',
  'auth.error.profileIncomplete':
      'Spelarprofilen var ofullständig; försök igen.',
  'auth.error.refreshExpired': 'Sessionen har gått ut; logga in igen.',
  'auth.error.refresh': 'Kunde inte förnya sessionen: {detail}',
  'auth.error.refreshIncomplete':
      'Förnyelsesvaret var ofullständigt; logga in igen.',

  // Licenses
  'licenses.title': 'Licenser',
  'licenses.count': '{count} poster',
  'licenses.loading': 'Läser licenslistan…',
  'licenses.viewText': 'Visa text →',
  'licenses.unsigned': '(Utan angivande)',
  'licenses.noText': '(Ingen licenstext angiven)',

  // Launch errors
  'launch.error.manifestMissing': 'Versionsmanifest hittades inte: {name}',
  'launch.error.manifestRead':
      'Kunde inte läsa versionsmanifestet för {name}: {error}',
  'launch.error.inheritCycle': 'Versionsarvsloop: {name}',
  'launch.error.javaPath': 'Inte en användbar Java-körbar fil: {path}',
  'launch.error.noJava':
      'Ingen Java-runtime hittades. Ange Java-sökvägen i '
      'versionsinställningarna.',
  'launch.error.javaTooOld':
      'Den här versionen kräver Java {required}, men Java {found} hittades.',
  'launch.error.missingClient': 'Klient-jar saknas: {path}',
  'launch.error.missingLibrary': 'Biblioteksfil saknas: {path}',
  'launch.error.missingAssetsIndex':
      'Det här versionsmanifestet har inget tillgångsindex.',
  'launch.error.missingAssets': 'Tillgångsindex saknas: {path}',
  'launch.error.noMainClass':
      'Det här versionsmanifestet har ingen huvudklass.',
  'launch.error.natives': 'Kunde inte extrahera natives: {error}',
  'launch.error.start': 'Kunde inte starta spelet: {error}',
  'launch.error.alreadyRunning': 'Den här versionen körs redan.',
  'launch.loginRequired': 'Logga in för att starta spelet.',
  'launch.starting': 'Startar…',
  'launch.log': 'Logg',
  'launch.stop': 'Stoppa',
  'launch.logTitle': 'Spellogg · {name}',

  // Loaders
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
