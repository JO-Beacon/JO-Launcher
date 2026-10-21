// Español.

const Map<String, String> stringsEs = <String, String>{
  // Común
  'common.cancel': 'Cancelar',
  'common.close': 'Cerrar',
  'common.retry': 'Reintentar',
  'common.back': 'Atrás',
  'common.save': 'Guardar',
  'common.saving': 'Guardando…',
  'common.saved': 'Guardado.',
  'common.login': 'Iniciar sesión',
  'common.logout': 'Cerrar sesión',
  'common.delete': 'Eliminar',
  'common.change': 'Cambiar',
  'common.view': 'Ver',
  'common.openFolder': 'Abrir carpeta',
  'common.notYet': 'Aún no disponible',
  'common.auto': 'Automático',
  'common.manual': 'Manual',
  'common.enabled': 'Activado',
  'common.disabled': 'Desactivado',
  'common.keyPress': 'Pulsa una combinación de teclas…',
  'common.keyUnset': 'Sin definir',
  'common.loading': 'Cargando…',
  'common.listSeparator': ', ',

  // Navegación y barra lateral
  'nav.launch': 'Iniciar',
  'nav.version': 'Ajustes de la versión',
  'nav.settings': 'Ajustes',
  'rail.microsoftLogin': 'Inicio de sesión de Microsoft',

  // Privacidad
  'privacy.title': 'Privacidad',
  'privacy.hint': 'Cómo se tratan los datos locales de la cuenta',
  'privacy.summary':
      'JO-Launcher procesa en este dispositivo el nombre de tu cuenta de '
      'Microsoft, tu nombre de jugador y UUID de Minecraft, los tokens de '
      'inicio de sesión (access y refresh) y los datos de perfil / skin.\n\n'
      'Los datos se guardan solo en un archivo local protegido por DPAPI de '
      'Windows (via flutter_secure_storage) y se usan para iniciar sesión, '
      'renovar la sesión y iniciar el juego. No se suben a servidores de '
      'JO-Launcher y la aplicación no tiene telemetría.\n\n'
      'Durante el inicio de sesión, los datos se envían a los servicios de '
      'Microsoft, Xbox y Minecraft conforme a sus políticas de privacidad.\n\n'
      'Puedes eliminar estos datos en cualquier momento en Ajustes → Cuenta → '
      'Eliminar cuenta y datos locales.',
  'privacy.agree': 'Aceptar y continuar',
  'privacy.fullNotice': 'Abrir aviso de privacidad completo',
  'privacy.linkError': 'No se pudo abrir el aviso de privacidad.',

  // Página de inicio
  'launch.title': 'Iniciar',
  'launch.subtitle': 'Versión actual e instancias en ejecución',
  'launch.rescan': 'Volver a analizar',
  'launch.scanError': 'No se pudo leer el directorio del juego: {error}',
  'launch.noVersionsDir': 'No hay una carpeta versions en este directorio.',
  'launch.noVersions': 'Todavía no hay versiones que se puedan iniciar.',
  'launch.chooseVersion': 'Elige una versión para iniciar',
  'launch.versionCount': 'Este directorio contiene {count} versiones.',
  'launch.switch': 'Cambiar',
  'launch.collapse': 'Contraer',
  'launch.launchGame': 'Iniciar juego',
  'launch.notImplemented': 'La función de inicio aún no está implementada.',
  'launch.running': 'En ejecución',
  'launch.noneRunning': 'No hay juegos en ejecución.',
  'launch.broken':
      'Otras {count} carpetas no tienen un manifiesto legible: {names}',

  // Ajustes de la versión
  'version.title': 'Ajustes de la versión',
  'version.current': 'Versión actual',
  'version.reload': 'Recargar',
  'version.pickFirst': 'Elige primero una versión en la página Iniciar.',
  'version.goLaunch': 'Ir a Iniciar',
  'version.versionSection': 'Versión',
  'version.name': 'Nombre',
  'version.gameVersion': 'Versión del juego',
  'version.loader': 'Cargador',
  'version.directory': 'Directorio',
  'version.javaSection': 'Java',
  'version.javaSource': 'Origen',
  'version.javaAutoHint': 'Automático = detectar al iniciar',
  'version.javaPathHint': 'Ruta completa de java.exe / javaw.exe',
  'version.memorySection': 'Memoria',
  'version.memoryMin': 'Mínima',
  'version.memoryMax': 'Máxima',
  'version.memoryHint': 'MB, vacío = automático',
  'version.jvmSection': 'Argumentos de la JVM',
  'version.jvmHint': 'p. ej. -XX:+UseG1GC, vacío = ninguno',
  'version.errorRead': 'No se pudieron leer los ajustes de la versión: {error}',
  'version.errorOpenFolder': 'No se pudo abrir la carpeta.',
  'version.errorMemoryNumber':
      'La memoria debe ser un número entero positivo o quedar vacía.',
  'version.errorMemoryPositive': 'La memoria debe ser mayor que 0.',
  'version.errorMemoryOrder': 'La memoria mínima no puede superar la máxima.',
  'version.errorWrite': 'No se pudo escribir jolauncher.json: {error}',

  // Ajustes
  'settings.title': 'Ajustes',
  'settings.subtitle': 'Apariencia, directorio y acerca de',
  'settings.sectionLanguage': 'Idioma',
  'settings.language': 'Idioma de la interfaz',
  'settings.languageSystem': 'Seguir el sistema',
  'settings.sectionAppearance': 'Apariencia',
  'settings.dark': 'Oscuro',
  'settings.light': 'Claro',
  'settings.darkHint': 'Siguiendo el sistema; esta opción no tiene efecto',
  'settings.followSystem': 'Seguir el sistema',
  'settings.followSystemHint': 'Seguir la apariencia del sistema',
  'settings.sectionGameDir': 'Directorio del juego',
  'settings.currentDir': 'Directorio actual',
  'settings.sectionAccount': 'Cuenta',
  'settings.microsoftAccount': 'Cuenta de Microsoft',
  'settings.loginToPlay': 'Inicia sesión para jugar',
  'settings.characterName': 'Nombre del jugador',
  'settings.loginStatus': 'Estado de la sesión',
  'settings.autoRenew': 'Los tokens se renuevan automáticamente al caducar',
  'settings.deleteAccount': 'Eliminar cuenta y datos locales',
  'settings.deleteAccountHint':
      'Elimina la cuenta, los tokens y el perfil en caché de este dispositivo.',
  'settings.deleteAccountTitle': '¿Eliminar cuenta y datos locales?',
  'settings.deleteAccountMessage':
      'Esto elimina la cuenta conectada, el token de acceso, el token de '
      'actualización y el perfil en caché de este dispositivo. Los archivos '
      'del juego y los ajustes de versión no se eliminan. No se puede '
      'deshacer.',
  'settings.deleteAccountError':
      'No se pudieron eliminar los datos locales de la cuenta: {error}',
  'settings.sectionAbout': 'Acerca de',
  'settings.version': 'Versión',
  'settings.licenses': 'Licencias',
  'settings.licensesHint': 'Esta aplicación y componentes de terceros',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'NO ES UN PRODUCTO OFICIAL DE MINECRAFT. NO ESTÁ APROBADO POR MOJANG NI '
      'POR MICROSOFT, NI ESTÁ ASOCIADO CON ELLOS.',
  'settings.versionReadError': 'No se pudo leer',
  'settings.pickerError': 'No se pudo abrir el selector de carpetas: {error}',

  // Inicio de sesión de Microsoft
  'auth.title': 'Inicio de sesión de Microsoft',
  'auth.requesting': 'Solicitando un código de inicio de sesión…',
  'auth.instructions':
      'Abre el siguiente enlace en el navegador e introduce el código:',
  'auth.copyCode': 'Copiar código',
  'auth.openLink': 'Abrir enlace',
  'auth.waiting': 'Esperando autorización…',
  'auth.copied': 'Código copiado.',
  'auth.openBrowserFailed':
      'No se pudo abrir el navegador; copia el enlace manualmente.',
  'auth.errorGeneric': 'Error al iniciar sesión: {error}',
  'auth.error.noClientId':
      'Esta compilación no tiene configurado un client_id de Microsoft; el '
      'inicio de sesión no está disponible. Define la variable de entorno '
      'JO_MS_CLIENT_ID o pasa --dart-define=JO_MS_CLIENT_ID=... al compilar.',
  'auth.error.timeout': 'El inicio de sesión ha caducado; inténtalo de nuevo.',
  'auth.error.declined':
      'Has rechazado el inicio de sesión en la página de autorización.',
  'auth.error.codeExpired':
      'El código de inicio de sesión ha caducado; inténtalo de nuevo.',
  'auth.error.codeInvalid':
      'El código de inicio de sesión no es válido; inténtalo de nuevo.',
  'auth.error.deviceCode':
      'No se pudo solicitar un código de inicio de sesión: {detail}',
  'auth.error.deviceCodeIncomplete':
      'La respuesta del código de inicio de sesión estaba incompleta; '
      'inténtalo de nuevo.',
  'auth.error.tokenIncomplete':
      'La respuesta del token estaba incompleta; inténtalo de nuevo.',
  'auth.error.ms': 'Error al iniciar sesión en Microsoft: {detail}',
  'auth.error.xbox': 'Error de autenticación de Xbox Live: {detail}',
  'auth.error.xsts': 'Error de autorización de Xbox: {detail}',
  'auth.error.xboxRejected':
      'La autorización de Xbox fue rechazada; comprueba el estado de la cuenta.',
  'auth.error.xboxNoProfile':
      'Esta cuenta de Microsoft aún no tiene un perfil de Xbox. Inicia sesión '
      'una vez en xbox.com y vuelve a intentarlo.',
  'auth.error.xboxRegion': 'Xbox Live no está disponible en esta región.',
  'auth.error.xboxChild':
      'Esta es una cuenta infantil; añádela primero a una familia de Microsoft.',
  'auth.error.xboxCode': 'Error de autorización de Xbox (XErr {xerr}).',
  'auth.error.whitelist':
      'Mojang aún no ha añadido JO-Launcher a la lista de aplicaciones '
      'permitidas (Invalid app registration); este paso no puede continuar.',
  'auth.error.minecraftRejected':
      'El inicio de sesión de Minecraft fue rechazado: {detail}',
  'auth.error.minecraft': 'Error al iniciar sesión en Minecraft: {detail}',
  'auth.error.minecraftTokenIncomplete':
      'La respuesta del token de Minecraft estaba incompleta; inténtalo de nuevo.',
  'auth.error.noJavaEdition':
      'Esta cuenta de Microsoft no posee Minecraft: Java Edition.',
  'auth.error.profile': 'No se pudo leer el perfil del jugador: {detail}',
  'auth.error.profileIncomplete':
      'El perfil del jugador estaba incompleto; inténtalo de nuevo.',
  'auth.error.refreshExpired': 'La sesión ha caducado; inicia sesión de nuevo.',
  'auth.error.refresh': 'No se pudo renovar la sesión: {detail}',
  'auth.error.refreshIncomplete':
      'La respuesta de renovación estaba incompleta; inicia sesión de nuevo.',

  // Licencias
  'licenses.title': 'Licencias',
  'licenses.count': '{count} entradas',
  'licenses.loading': 'Leyendo la lista de licencias…',
  'licenses.viewText': 'Ver texto →',
  'licenses.unsigned': '(Sin atribución)',
  'licenses.noText': '(No se proporciona texto de licencia)',

  // Errores de inicio
  'launch.error.manifestMissing':
      'No se encontró el manifiesto de la versión: {name}',
  'launch.error.manifestRead':
      'No se pudo leer el manifiesto de la versión {name}: {error}',
  'launch.error.inheritCycle': 'Herencia de versiones en bucle: {name}',
  'launch.error.javaPath': 'No es un ejecutable de Java utilizable: {path}',
  'launch.error.noJava':
      'No se encontró ningún entorno de ejecución de Java. Indica la ruta de Java en los ajustes de la versión.',
  'launch.error.javaTooOld':
      'Esta versión requiere Java {required}, pero se encontró Java {found}.',
  'launch.error.missingClient': 'Falta el jar del cliente: {path}',
  'launch.error.missingLibrary': 'Falta un archivo de biblioteca: {path}',
  'launch.error.missingAssetsIndex':
      'El manifiesto de esta versión no tiene índice de recursos.',
  'launch.error.missingAssets': 'Falta el índice de recursos: {path}',
  'launch.error.noMainClass':
      'El manifiesto de esta versión no tiene clase principal.',
  'launch.error.natives': 'No se pudieron extraer los natives: {error}',
  'launch.error.start': 'No se pudo iniciar el juego: {error}',
  'launch.error.alreadyRunning': 'Esta versión ya se está ejecutando.',
  'launch.loginRequired': 'Inicia sesión para jugar.',
  'launch.starting': 'Iniciando…',
  'launch.log': 'Registro',
  'launch.stop': 'Detener',
  'launch.logTitle': 'Registro del juego · {name}',

  // Cargadores
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
