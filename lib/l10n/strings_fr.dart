// Français.

const Map<String, String> stringsFr = <String, String>{
  // Commun
  'common.cancel': 'Annuler',
  'common.close': 'Fermer',
  'common.retry': 'Réessayer',
  'common.back': 'Retour',
  'common.save': 'Enregistrer',
  'common.saving': 'Enregistrement…',
  'common.saved': 'Enregistré.',
  'common.login': 'Se connecter',
  'common.logout': 'Se déconnecter',
  'common.delete': 'Supprimer',
  'common.change': 'Modifier',
  'common.view': 'Voir',
  'common.openFolder': 'Ouvrir le dossier',
  'common.notYet': 'Pas encore disponible',
  'common.auto': 'Automatique',
  'common.manual': 'Manuel',
  'common.enabled': 'Activé',
  'common.disabled': 'Désactivé',
  'common.keyPress': 'Appuyez sur une combinaison de touches…',
  'common.keyUnset': 'Non défini',
  'common.loading': 'Chargement…',
  'common.listSeparator': ', ',

  // Navigation et barre latérale
  'nav.launch': 'Lancer',
  'nav.version': 'Paramètres de version',
  'nav.settings': 'Paramètres',
  'rail.microsoftLogin': 'Connexion Microsoft',

  // Confidentialité
  'privacy.title': 'Confidentialité',
  'privacy.hint': 'Comment les données locales du compte sont traitées',
  'privacy.summary':
      'JO-Launcher traite sur cet appareil le nom de votre compte Microsoft, '
      'votre nom de joueur et UUID Minecraft, les jetons de connexion '
      '(access et refresh) ainsi que les données de profil / skin.\n\n'
      'Ces données sont stockées uniquement dans un fichier local protégé '
      'par la DPAPI Windows (via flutter_secure_storage) et servent à la '
      'connexion, au renouvellement de session et au lancement du jeu. Elles '
      'ne sont pas envoyées aux serveurs de JO-Launcher et l’application n’a '
      'pas de télémétrie.\n\n'
      'Lors de la connexion, les données sont transmises aux services '
      'Microsoft, Xbox et Minecraft selon leurs politiques de '
      'confidentialité.\n\n'
      'Vous pouvez supprimer ces données à tout moment dans Paramètres → '
      'Compte → Supprimer le compte et les données locales.',
  'privacy.agree': 'Accepter et continuer',
  'privacy.fullNotice': 'Ouvrir l’avis de confidentialité complet',
  'privacy.linkError': 'Impossible d’ouvrir l’avis de confidentialité.',

  // Page de lancement
  'launch.title': 'Lancer',
  'launch.subtitle': 'Version actuelle et instances en cours',
  'launch.rescan': 'Rescanner',
  'launch.scanError': 'Impossible de lire le répertoire du jeu : {error}',
  'launch.noVersionsDir':
      "Il n'y a pas de dossier versions dans ce répertoire.",
  'launch.noVersions': 'Aucune version lançable pour l’instant.',
  'launch.chooseVersion': 'Choisissez une version à lancer',
  'launch.versionCount': 'Ce répertoire contient {count} versions.',
  'launch.switch': 'Changer',
  'launch.collapse': 'Réduire',
  'launch.launchGame': 'Lancer le jeu',
  'launch.notImplemented': "Le lancement n'est pas encore implémenté.",
  'launch.running': 'En cours',
  'launch.noneRunning': 'Aucun jeu en cours.',
  'launch.broken':
      "{count} autres dossiers n'ont pas de manifeste lisible : {names}",

  // Paramètres de version
  'version.title': 'Paramètres de version',
  'version.current': 'Version actuelle',
  'version.reload': 'Recharger',
  'version.pickFirst': "Choisissez d'abord une version sur la page Lancer.",
  'version.goLaunch': 'Aller au lancement',
  'version.versionSection': 'Version',
  'version.name': 'Nom',
  'version.gameVersion': 'Version du jeu',
  'version.loader': 'Chargeur',
  'version.directory': 'Répertoire',
  'version.javaSection': 'Java',
  'version.javaSource': 'Source',
  'version.javaAutoHint': 'Automatique = détecter au lancement',
  'version.javaPathHint': 'Chemin complet vers java.exe / javaw.exe',
  'version.memorySection': 'Mémoire',
  'version.memoryMin': 'Minimale',
  'version.memoryMax': 'Maximale',
  'version.memoryHint': 'Mo, vide = automatique',
  'version.jvmSection': 'Arguments JVM',
  'version.jvmHint': 'ex. : -XX:+UseG1GC, vide = aucun',
  'version.errorRead': 'Impossible de lire les paramètres de version : {error}',
  'version.errorOpenFolder': 'Impossible d’ouvrir le dossier.',
  'version.errorMemoryNumber':
      'La mémoire doit être un entier positif ou rester vide.',
  'version.errorMemoryPositive': 'La mémoire doit être supérieure à 0.',
  'version.errorMemoryOrder':
      'La mémoire minimale ne peut pas dépasser la maximale.',
  'version.errorWrite': 'Impossible d’écrire jolauncher.json : {error}',

  // Paramètres
  'settings.title': 'Paramètres',
  'settings.subtitle': 'Apparence, répertoire et à propos',
  'settings.sectionLanguage': 'Langue',
  'settings.language': 'Langue d’affichage',
  'settings.languageSystem': 'Suivre le système',
  'settings.sectionAppearance': 'Apparence',
  'settings.dark': 'Sombre',
  'settings.light': 'Clair',
  'settings.darkHint': 'Le système est suivi ; ce réglage est sans effet',
  'settings.followSystem': 'Suivre le système',
  'settings.followSystemHint': 'Suivre l’apparence du système',
  'settings.sectionGameDir': 'Répertoire du jeu',
  'settings.currentDir': 'Répertoire actuel',
  'settings.sectionAccount': 'Compte',
  'settings.microsoftAccount': 'Compte Microsoft',
  'settings.loginToPlay': 'Connectez-vous pour lancer le jeu',
  'settings.characterName': 'Nom du joueur',
  'settings.loginStatus': 'État de connexion',
  'settings.autoRenew':
      'Les jetons se renouvellent automatiquement à expiration',
  'settings.deleteAccount': 'Supprimer le compte et les données locales',
  'settings.deleteAccountHint':
      'Supprime le compte, les jetons et le profil en cache de cet appareil.',
  'settings.deleteAccountTitle': 'Supprimer le compte et les données locales ?',
  'settings.deleteAccountMessage':
      'Cela supprime le compte connecté, le jeton d’accès, le jeton de '
      'rafraîchissement et le profil en cache de cet appareil. Les fichiers '
      'du jeu et les paramètres de version ne sont pas supprimés. Cette '
      'action est irréversible.',
  'settings.deleteAccountError':
      'Impossible de supprimer les données locales du compte : {error}',
  'settings.sectionAbout': 'À propos',
  'settings.version': 'Version',
  'settings.licenses': 'Licences',
  'settings.licensesHint': 'Cette application et les composants tiers',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'PAS UN PRODUIT OFFICIEL MINECRAFT. NON APPROUVÉ PAR MOJANG OU '
      'MICROSOFT, ET NON ASSOCIÉ À CES SOCIÉTÉS.',
  'settings.versionReadError': 'Impossible de lire',
  'settings.pickerError':
      'Impossible d’ouvrir le sélecteur de dossier : {error}',

  // Connexion Microsoft
  'auth.title': 'Connexion Microsoft',
  'auth.requesting': 'Demande d’un code de connexion…',
  'auth.instructions':
      'Ouvrez le lien ci-dessous dans votre navigateur et saisissez le code :',
  'auth.copyCode': 'Copier le code',
  'auth.openLink': 'Ouvrir le lien',
  'auth.waiting': 'En attente d’autorisation…',
  'auth.copied': 'Code copié.',
  'auth.openBrowserFailed':
      'Impossible d’ouvrir le navigateur ; copiez le lien manuellement.',
  'auth.errorGeneric': 'Échec de la connexion : {error}',
  'auth.error.noClientId':
      'Cette compilation n’a pas de client_id Microsoft configuré ; la '
      'connexion n’est pas disponible. Définissez la variable d’environnement '
      'JO_MS_CLIENT_ID ou passez --dart-define=JO_MS_CLIENT_ID=... à la '
      'compilation.',
  'auth.error.timeout': 'La connexion a expiré ; réessayez.',
  'auth.error.declined':
      'Vous avez refusé la connexion sur la page d’autorisation.',
  'auth.error.codeExpired': 'Le code de connexion a expiré ; réessayez.',
  'auth.error.codeInvalid': 'Le code de connexion est invalide ; réessayez.',
  'auth.error.deviceCode':
      'Impossible de demander un code de connexion : {detail}',
  'auth.error.deviceCodeIncomplete':
      'La réponse du code de connexion était incomplète ; réessayez.',
  'auth.error.tokenIncomplete':
      'La réponse du jeton était incomplète ; réessayez.',
  'auth.error.ms': 'Échec de la connexion Microsoft : {detail}',
  'auth.error.xbox': 'Échec de l’authentification Xbox Live : {detail}',
  'auth.error.xsts': 'Échec de l’autorisation Xbox : {detail}',
  'auth.error.xboxRejected':
      'L’autorisation Xbox a été refusée ; vérifiez l’état du compte.',
  'auth.error.xboxNoProfile':
      'Ce compte Microsoft n’a pas encore de profil Xbox. Connectez-vous une '
      'fois sur xbox.com, puis réessayez.',
  'auth.error.xboxRegion': 'Xbox Live n’est pas disponible dans cette région.',
  'auth.error.xboxChild':
      'Il s’agit d’un compte enfant ; ajoutez-le d’abord à une famille '
      'Microsoft.',
  'auth.error.xboxCode': 'Échec de l’autorisation Xbox (XErr {xerr}).',
  'auth.error.whitelist':
      'Mojang n’a pas encore ajouté JO-Launcher à la liste d’applications '
      'autorisées (Invalid app registration) ; cette étape ne peut pas '
      'aboutir.',
  'auth.error.minecraftRejected':
      'La connexion Minecraft a été refusée : {detail}',
  'auth.error.minecraft': 'Échec de la connexion Minecraft : {detail}',
  'auth.error.minecraftTokenIncomplete':
      'La réponse du jeton Minecraft était incomplète ; réessayez.',
  'auth.error.noJavaEdition':
      'Ce compte Microsoft ne possède pas Minecraft: Java Edition.',
  'auth.error.profile': 'Impossible de lire le profil du joueur : {detail}',
  'auth.error.profileIncomplete':
      'Le profil du joueur était incomplet ; réessayez.',
  'auth.error.refreshExpired': 'La session a expiré ; reconnectez-vous.',
  'auth.error.refresh': 'Impossible de renouveler la session : {detail}',
  'auth.error.refreshIncomplete':
      'La réponse de renouvellement était incomplète ; reconnectez-vous.',

  // Licences
  'licenses.title': 'Licences',
  'licenses.count': '{count} entrées',
  'licenses.loading': 'Lecture de la liste des licences…',
  'licenses.viewText': 'Voir le texte →',
  'licenses.unsigned': '(Non attribué)',
  'licenses.noText': '(Aucun texte de licence fourni)',

  // Erreurs de lancement
  'launch.error.manifestMissing': 'Manifeste de version introuvable : {name}',
  'launch.error.manifestRead':
      'Impossible de lire le manifeste de la version {name} : {error}',
  'launch.error.inheritCycle': 'Héritage de version en boucle : {name}',
  'launch.error.javaPath':
      'Ce n’est pas un exécutable Java utilisable : {path}',
  'launch.error.noJava':
      'Aucun runtime Java trouvé. Indiquez le chemin de Java dans les paramètres de version.',
  'launch.error.javaTooOld':
      'Cette version nécessite Java {required}, mais Java {found} a été trouvé.',
  'launch.error.missingClient': 'Le jar client est absent : {path}',
  'launch.error.missingLibrary': 'Fichier de bibliothèque absent : {path}',
  'launch.error.missingAssetsIndex':
      'Le manifeste de cette version n’a pas d’index d’assets.',
  'launch.error.missingAssets': 'Index d’assets absent : {path}',
  'launch.error.noMainClass':
      'Le manifeste de cette version n’a pas de classe principale.',
  'launch.error.natives': 'Impossible d’extraire les natives : {error}',
  'launch.error.start': 'Impossible de lancer le jeu : {error}',
  'launch.error.alreadyRunning': 'Cette version est déjà en cours d’exécution.',
  'launch.loginRequired': 'Connectez-vous pour lancer le jeu.',
  'launch.starting': 'Lancement…',
  'launch.log': 'Journal',
  'launch.stop': 'Arrêter',
  'launch.logTitle': 'Journal du jeu · {name}',

  // Chargeurs
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
