// Deutsch.

const Map<String, String> stringsDe = <String, String>{
  // Allgemein
  'common.cancel': 'Abbrechen',
  'common.close': 'Schließen',
  'common.retry': 'Erneut versuchen',
  'common.back': 'Zurück',
  'common.save': 'Speichern',
  'common.saving': 'Speichern…',
  'common.saved': 'Gespeichert.',
  'common.login': 'Anmelden',
  'common.logout': 'Abmelden',
  'common.delete': 'Löschen',
  'common.change': 'Ändern',
  'common.view': 'Ansehen',
  'common.openFolder': 'Ordner öffnen',
  'common.notYet': 'Noch nicht verfügbar',
  'common.auto': 'Automatisch',
  'common.manual': 'Manuell',
  'common.enabled': 'Aktiviert',
  'common.disabled': 'Deaktiviert',
  'common.keyPress': 'Tastenkombination drücken…',
  'common.keyUnset': 'Nicht festgelegt',
  'common.loading': 'Wird geladen…',
  'common.listSeparator': ', ',

  // Navigation und Seitenleiste
  'nav.launch': 'Start',
  'nav.version': 'Versionseinstellungen',
  'nav.settings': 'Einstellungen',
  'rail.microsoftLogin': 'Microsoft-Anmeldung',

  // Datenschutz
  'privacy.title': 'Datenschutz',
  'privacy.hint': 'Wie lokale Kontodaten verarbeitet werden',
  'privacy.summary':
      'JO-Launcher verarbeitet auf diesem Gerät deinen Microsoft-Kontonamen, '
      'deinen Minecraft-Spielernamen und deine UUID, Anmeldetokens (Access- '
      'und Refresh-Token) sowie Profil-/Skin-Daten.\n\n'
      'Die Daten werden nur in einer lokalen Datei gespeichert, die durch '
      'Windows DPAPI (via flutter_secure_storage) geschützt ist, und für '
      'Anmeldung, Sitzungsverlängerung und Spielstart verwendet. Sie '
      'werden nicht auf JO-Launcher-Server hochgeladen; die App enthält keine '
      'Telemetrie.\n\n'
      'Bei der Anmeldung werden Daten gemäß den jeweiligen '
      'Datenschutzrichtlinien an Microsoft-, Xbox- und Minecraft-Dienste '
      'übermittelt.\n\n'
      'Du kannst diese Daten jederzeit unter Einstellungen → Konto → Konto '
      'und lokale Daten löschen entfernen.',
  'privacy.agree': 'Zustimmen und fortfahren',
  'privacy.fullNotice': 'Vollständige Datenschutzhinweise öffnen',
  'privacy.linkError': 'Datenschutzhinweise konnten nicht geöffnet werden.',

  // Startseite
  'launch.title': 'Start',
  'launch.subtitle': 'Aktuelle Version und laufende Instanzen',
  'launch.rescan': 'Erneut suchen',
  'launch.scanError': 'Spielverzeichnis konnte nicht gelesen werden: {error}',
  'launch.noVersionsDir':
      'In diesem Verzeichnis gibt es keinen versions-Ordner.',
  'launch.noVersions': 'Noch keine startbaren Versionen.',
  'launch.chooseVersion': 'Wähle eine Version zum Starten',
  'launch.versionCount': 'Dieses Verzeichnis enthält {count} Versionen.',
  'launch.switch': 'Wechseln',
  'launch.collapse': 'Einklappen',
  'launch.launchGame': 'Spiel starten',
  'launch.notImplemented': 'Der Start ist noch nicht implementiert.',
  'launch.running': 'Laufend',
  'launch.noneRunning': 'Es laufen keine Spiele.',
  'launch.broken':
      '{count} weitere Ordner haben kein lesbares Manifest: {names}',

  // Versionseinstellungen
  'version.title': 'Versionseinstellungen',
  'version.current': 'Aktuelle Version',
  'version.reload': 'Neu laden',
  'version.pickFirst': 'Wähle zuerst eine Version auf der Startseite.',
  'version.goLaunch': 'Zum Start',
  'version.versionSection': 'Version',
  'version.name': 'Name',
  'version.gameVersion': 'Spielversion',
  'version.loader': 'Loader',
  'version.directory': 'Verzeichnis',
  'version.javaSection': 'Java',
  'version.javaSource': 'Quelle',
  'version.javaAutoHint': 'Automatisch = beim Start erkennen',
  'version.javaPathHint': 'Vollständiger Pfad zu java.exe / javaw.exe',
  'version.memorySection': 'Arbeitsspeicher',
  'version.memoryMin': 'Minimum',
  'version.memoryMax': 'Maximum',
  'version.memoryHint': 'MB, leer = automatisch',
  'version.jvmSection': 'JVM-Argumente',
  'version.jvmHint': 'z. B. -XX:+UseG1GC, leer = keine',
  'version.errorRead':
      'Versionseinstellungen konnten nicht gelesen werden: {error}',
  'version.errorOpenFolder': 'Der Ordner konnte nicht geöffnet werden.',
  'version.errorMemoryNumber':
      'Der Arbeitsspeicher muss eine positive Ganzzahl sein oder leer bleiben.',
  'version.errorMemoryPositive': 'Der Arbeitsspeicher muss größer als 0 sein.',
  'version.errorMemoryOrder':
      'Der minimale Arbeitsspeicher darf den maximalen nicht überschreiten.',
  'version.errorWrite':
      'jolauncher.json konnte nicht geschrieben werden: {error}',

  // Einstellungen
  'settings.title': 'Einstellungen',
  'settings.subtitle': 'Darstellung, Verzeichnis und Info',
  'settings.sectionLanguage': 'Sprache',
  'settings.language': 'Anzeigesprache',
  'settings.languageSystem': 'Systemeinstellung folgen',
  'settings.sectionAppearance': 'Darstellung',
  'settings.dark': 'Dunkel',
  'settings.light': 'Hell',
  'settings.darkHint':
      'Systemeinstellung wird gefolgt; diese Option hat keine Wirkung',
  'settings.followSystem': 'Systemeinstellung folgen',
  'settings.followSystemHint': 'Der Darstellung des Systems folgen',
  'settings.sectionGameDir': 'Spielverzeichnis',
  'settings.currentDir': 'Aktuelles Verzeichnis',
  'settings.sectionAccount': 'Konto',
  'settings.microsoftAccount': 'Microsoft-Konto',
  'settings.loginToPlay': 'Melde dich an, um das Spiel zu starten',
  'settings.characterName': 'Spielername',
  'settings.loginStatus': 'Anmeldestatus',
  'settings.autoRenew': 'Tokens werden bei Ablauf automatisch erneuert',
  'settings.deleteAccount': 'Konto und lokale Daten löschen',
  'settings.deleteAccountHint':
      'Entfernt Konto, Token und zwischengespeichertes Profil von diesem Gerät.',
  'settings.deleteAccountTitle': 'Konto und lokale Daten löschen?',
  'settings.deleteAccountMessage':
      'Entfernt das angemeldete Konto, Access-Token, Refresh-Token und das '
      'zwischengespeicherte Profil von diesem Gerät. Spieldateien und '
      'Versionseinstellungen werden nicht gelöscht. Dies kann nicht '
      'rückgängig gemacht werden.',
  'settings.deleteAccountError':
      'Lokale Kontodaten konnten nicht gelöscht werden: {error}',
  'settings.sectionAbout': 'Über',
  'settings.version': 'Version',
  'settings.licenses': 'Lizenzen',
  'settings.licensesHint': 'Diese App und Drittanbieter-Komponenten',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'KEIN OFFIZIELLES MINECRAFT-PRODUKT. NICHT VON MOJANG ODER MICROSOFT '
      'GENEHMIGT UND NICHT MIT DIESEN VERBUNDEN.',
  'settings.versionReadError': 'Konnte nicht gelesen werden',
  'settings.pickerError':
      'Der Ordnerauswahldialog konnte nicht geöffnet werden: {error}',

  // Microsoft-Anmeldung
  'auth.title': 'Microsoft-Anmeldung',
  'auth.requesting': 'Anmeldecode wird angefordert…',
  'auth.instructions':
      'Öffne den folgenden Link im Browser und gib den Code ein:',
  'auth.copyCode': 'Code kopieren',
  'auth.openLink': 'Link öffnen',
  'auth.waiting': 'Warte auf Autorisierung…',
  'auth.copied': 'Code kopiert.',
  'auth.openBrowserFailed':
      'Der Browser konnte nicht geöffnet werden; kopiere den Link manuell.',
  'auth.errorGeneric': 'Anmeldung fehlgeschlagen: {error}',
  'auth.error.noClientId':
      'Für diesen Build ist keine Microsoft-client_id konfiguriert; die '
      'Anmeldung ist nicht verfügbar. Setze die Umgebungsvariable '
      'JO_MS_CLIENT_ID oder übergib beim Build '
      '--dart-define=JO_MS_CLIENT_ID=....',
  'auth.error.timeout': 'Die Anmeldung ist abgelaufen; versuche es erneut.',
  'auth.error.declined':
      'Du hast die Anmeldung auf der Autorisierungsseite abgelehnt.',
  'auth.error.codeExpired':
      'Der Anmeldecode ist abgelaufen; versuche es erneut.',
  'auth.error.codeInvalid': 'Der Anmeldecode ist ungültig; versuche es erneut.',
  'auth.error.deviceCode':
      'Anmeldecode konnte nicht angefordert werden: {detail}',
  'auth.error.deviceCodeIncomplete':
      'Die Antwort des Anmeldecodes war unvollständig; versuche es erneut.',
  'auth.error.tokenIncomplete':
      'Die Token-Antwort war unvollständig; versuche es erneut.',
  'auth.error.ms': 'Microsoft-Anmeldung fehlgeschlagen: {detail}',
  'auth.error.xbox': 'Xbox-Live-Authentifizierung fehlgeschlagen: {detail}',
  'auth.error.xsts': 'Xbox-Autorisierung fehlgeschlagen: {detail}',
  'auth.error.xboxRejected':
      'Die Xbox-Autorisierung wurde abgelehnt; prüfe den Kontostatus.',
  'auth.error.xboxNoProfile':
      'Dieses Microsoft-Konto hat noch kein Xbox-Profil. Melde dich einmal '
      'auf xbox.com an und versuche es erneut.',
  'auth.error.xboxRegion': 'Xbox Live ist in dieser Region nicht verfügbar.',
  'auth.error.xboxChild':
      'Dies ist ein Kinderkonto; füge es zuerst einer Microsoft-Familie hinzu.',
  'auth.error.xboxCode': 'Xbox-Autorisierung fehlgeschlagen (XErr {xerr}).',
  'auth.error.whitelist':
      'Mojang hat JO-Launcher noch nicht zur Allowlist für Anwendungen '
      'hinzugefügt (Invalid app registration); dieser Schritt kann nicht '
      'fortgesetzt werden.',
  'auth.error.minecraftRejected':
      'Die Minecraft-Anmeldung wurde abgelehnt: {detail}',
  'auth.error.minecraft': 'Minecraft-Anmeldung fehlgeschlagen: {detail}',
  'auth.error.minecraftTokenIncomplete':
      'Die Minecraft-Token-Antwort war unvollständig; versuche es erneut.',
  'auth.error.noJavaEdition':
      'Dieses Microsoft-Konto besitzt Minecraft: Java Edition nicht.',
  'auth.error.profile':
      'Das Spielerprofil konnte nicht gelesen werden: {detail}',
  'auth.error.profileIncomplete':
      'Das Spielerprofil war unvollständig; versuche es erneut.',
  'auth.error.refreshExpired':
      'Die Sitzung ist abgelaufen; melde dich erneut an.',
  'auth.error.refresh': 'Die Sitzung konnte nicht erneuert werden: {detail}',
  'auth.error.refreshIncomplete':
      'Die Erneuerungsantwort war unvollständig; melde dich erneut an.',

  // Lizenzen
  'licenses.title': 'Lizenzen',
  'licenses.count': '{count} Einträge',
  'licenses.loading': 'Lizenzliste wird gelesen…',
  'licenses.viewText': 'Text ansehen →',
  'licenses.unsigned': '(Ohne Zuordnung)',
  'licenses.noText': '(Kein Lizenztext vorhanden)',

  // Startfehler
  'launch.error.manifestMissing': 'Versionsmanifest nicht gefunden: {name}',
  'launch.error.manifestRead':
      'Das Versionsmanifest für {name} konnte nicht gelesen werden: {error}',
  'launch.error.inheritCycle': 'Versionsvererbung läuft im Kreis: {name}',
  'launch.error.javaPath': 'Keine nutzbare Java-Datei: {path}',
  'launch.error.noJava':
      'Keine Java-Laufzeit gefunden. Lege den Java-Pfad in den Versionseinstellungen fest.',
  'launch.error.javaTooOld':
      'Diese Version benötigt Java {required}, gefunden wurde Java {found}.',
  'launch.error.missingClient': 'Client-Jar fehlt: {path}',
  'launch.error.missingLibrary': 'Bibliotheksdatei fehlt: {path}',
  'launch.error.missingAssetsIndex':
      'Das Manifest dieser Version hat keinen Asset-Index.',
  'launch.error.missingAssets': 'Asset-Index fehlt: {path}',
  'launch.error.noMainClass':
      'Das Manifest dieser Version hat keine Hauptklasse.',
  'launch.error.natives': 'Natives konnten nicht entpackt werden: {error}',
  'launch.error.start': 'Das Spiel konnte nicht gestartet werden: {error}',
  'launch.error.alreadyRunning': 'Diese Version läuft bereits.',
  'launch.loginRequired': 'Melde dich an, um das Spiel zu starten.',
  'launch.starting': 'Wird gestartet…',
  'launch.log': 'Protokoll',
  'launch.stop': 'Beenden',
  'launch.logTitle': 'Spielprotokoll · {name}',

  // Loader
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
