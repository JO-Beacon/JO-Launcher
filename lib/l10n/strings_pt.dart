// Português (Brasil).

const Map<String, String> stringsPt = <String, String>{
  // Comum
  'common.cancel': 'Cancelar',
  'common.close': 'Fechar',
  'common.retry': 'Tentar novamente',
  'common.back': 'Voltar',
  'common.save': 'Salvar',
  'common.saving': 'Salvando…',
  'common.saved': 'Salvo.',
  'common.login': 'Entrar',
  'common.logout': 'Sair',
  'common.delete': 'Excluir',
  'common.change': 'Alterar',
  'common.view': 'Ver',
  'common.openFolder': 'Abrir pasta',
  'common.notYet': 'Ainda não disponível',
  'common.auto': 'Automático',
  'common.manual': 'Manual',
  'common.enabled': 'Ativado',
  'common.disabled': 'Desativado',
  'common.keyPress': 'Pressione uma combinação de teclas…',
  'common.keyUnset': 'Não definido',
  'common.loading': 'Carregando…',
  'common.listSeparator': ', ',

  // Navegação e barra lateral
  'nav.launch': 'Iniciar',
  'nav.version': 'Configurações da versão',
  'nav.settings': 'Configurações',
  'rail.microsoftLogin': 'Login da Microsoft',

  // Privacidade
  'privacy.title': 'Privacidade',
  'privacy.hint': 'Como os dados locais da conta são tratados',
  'privacy.summary':
      'O JO-Launcher processa neste dispositivo o nome da sua conta Microsoft, '
      'seu nome de jogador e UUID do Minecraft, tokens de login (access e '
      'refresh) e dados de perfil / skin.\n\n'
      'Os dados ficam apenas em um arquivo local protegido pela DPAPI do '
      'Windows (via flutter_secure_storage) e são usados para entrar, '
      'renovar a sessão e iniciar o jogo. Eles não são '
      'enviados aos servidores do JO-Launcher e o aplicativo não tem '
      'telemetria.\n\n'
      'Durante o login, os dados são enviados aos serviços da Microsoft, Xbox '
      'e Minecraft conforme as políticas de privacidade deles.\n\n'
      'Você pode excluir esses dados a qualquer momento em Configurações → '
      'Conta → Excluir conta e dados locais.',
  'privacy.agree': 'Concordar e continuar',
  'privacy.fullNotice': 'Abrir aviso de privacidade completo',
  'privacy.linkError': 'Não foi possível abrir o aviso de privacidade.',

  // Página inicial
  'launch.title': 'Iniciar',
  'launch.subtitle': 'Versão atual e instâncias em execução',
  'launch.rescan': 'Verificar novamente',
  'launch.scanError': 'Não foi possível ler o diretório do jogo: {error}',
  'launch.noVersionsDir': 'Não há uma pasta versions neste diretório.',
  'launch.noVersions': 'Ainda não há versões inicializáveis.',
  'launch.chooseVersion': 'Escolha uma versão para iniciar',
  'launch.versionCount': 'Este diretório contém {count} versões.',
  'launch.switch': 'Trocar',
  'launch.collapse': 'Recolher',
  'launch.launchGame': 'Iniciar jogo',
  'launch.notImplemented': 'A inicialização ainda não foi implementada.',
  'launch.running': 'Em execução',
  'launch.noneRunning': 'Nenhum jogo em execução.',
  'launch.broken': 'Mais {count} pastas não têm manifesto legível: {names}',

  // Configurações da versão
  'version.title': 'Configurações da versão',
  'version.current': 'Versão atual',
  'version.reload': 'Recarregar',
  'version.pickFirst': 'Escolha uma versão na página Iniciar primeiro.',
  'version.goLaunch': 'Ir para Iniciar',
  'version.versionSection': 'Versão',
  'version.name': 'Nome',
  'version.gameVersion': 'Versão do jogo',
  'version.loader': 'Loader',
  'version.directory': 'Diretório',
  'version.javaSection': 'Java',
  'version.javaSource': 'Origem',
  'version.javaAutoHint': 'Automático = detectar ao iniciar',
  'version.javaPathHint': 'Caminho completo para java.exe / javaw.exe',
  'version.memorySection': 'Memória',
  'version.memoryMin': 'Mínima',
  'version.memoryMax': 'Máxima',
  'version.memoryHint': 'MB, vazio = automático',
  'version.jvmSection': 'Argumentos da JVM',
  'version.jvmHint': 'ex.: -XX:+UseG1GC, vazio = nenhum',
  'version.errorRead':
      'Não foi possível ler as configurações da versão: {error}',
  'version.errorOpenFolder': 'Não foi possível abrir a pasta.',
  'version.errorMemoryNumber':
      'A memória deve ser um número inteiro positivo ou ficar vazia.',
  'version.errorMemoryPositive': 'A memória deve ser maior que 0.',
  'version.errorMemoryOrder':
      'A memória mínima não pode ser maior que a máxima.',
  'version.errorWrite': 'Não foi possível gravar jolauncher.json: {error}',

  // Configurações
  'settings.title': 'Configurações',
  'settings.subtitle': 'Aparência, diretório e sobre',
  'settings.sectionLanguage': 'Idioma',
  'settings.language': 'Idioma de exibição',
  'settings.languageSystem': 'Seguir o sistema',
  'settings.sectionAppearance': 'Aparência',
  'settings.dark': 'Escuro',
  'settings.light': 'Claro',
  'settings.darkHint': 'Seguindo o sistema; esta opção não tem efeito',
  'settings.followSystem': 'Seguir o sistema',
  'settings.followSystemHint': 'Seguir a aparência do sistema',
  'settings.sectionGameDir': 'Diretório do jogo',
  'settings.currentDir': 'Diretório atual',
  'settings.sectionAccount': 'Conta',
  'settings.microsoftAccount': 'Conta Microsoft',
  'settings.loginToPlay': 'Entre para iniciar o jogo',
  'settings.characterName': 'Nome do jogador',
  'settings.loginStatus': 'Status de login',
  'settings.autoRenew':
      'Os tokens são renovados automaticamente quando expiram',
  'settings.deleteAccount': 'Excluir conta e dados locais',
  'settings.deleteAccountHint':
      'Remove a conta, os tokens e o perfil em cache deste dispositivo.',
  'settings.deleteAccountTitle': 'Excluir conta e dados locais?',
  'settings.deleteAccountMessage':
      'Isso remove a conta conectada, o token de acesso, o token de '
      'atualização e o perfil em cache deste dispositivo. Os arquivos do jogo '
      'e as configurações de versão não são excluídos. Isso não pode ser '
      'desfeito.',
  'settings.deleteAccountError':
      'Não foi possível excluir os dados locais da conta: {error}',
  'settings.sectionAbout': 'Sobre',
  'settings.version': 'Versão',
  'settings.licenses': 'Licenças',
  'settings.licensesHint': 'Este aplicativo e componentes de terceiros',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'NÃO É UM PRODUTO OFICIAL DO MINECRAFT. NÃO APROVADO PELA MOJANG OU PELA '
      'MICROSOFT, NEM ASSOCIADO A ELAS.',
  'settings.versionReadError': 'Não foi possível ler',
  'settings.pickerError': 'Não foi possível abrir o seletor de pastas: {error}',

  // Login da Microsoft
  'auth.title': 'Login da Microsoft',
  'auth.requesting': 'Solicitando um código de login…',
  'auth.instructions': 'Abra o link abaixo no navegador e insira o código:',
  'auth.copyCode': 'Copiar código',
  'auth.openLink': 'Abrir link',
  'auth.waiting': 'Aguardando autorização…',
  'auth.copied': 'Código copiado.',
  'auth.openBrowserFailed':
      'Não foi possível abrir o navegador; copie o link manualmente.',
  'auth.errorGeneric': 'Falha no login: {error}',
  'auth.error.noClientId':
      'Esta compilação não tem um client_id da Microsoft configurado; o login '
      'não está disponível. Defina a variável de ambiente JO_MS_CLIENT_ID ou '
      'passe --dart-define=JO_MS_CLIENT_ID=... na compilação.',
  'auth.error.timeout': 'O login expirou; tente novamente.',
  'auth.error.declined': 'Você recusou o login na página de autorização.',
  'auth.error.codeExpired': 'O código de login expirou; tente novamente.',
  'auth.error.codeInvalid': 'O código de login é inválido; tente novamente.',
  'auth.error.deviceCode':
      'Não foi possível solicitar um código de login: {detail}',
  'auth.error.deviceCodeIncomplete':
      'A resposta do código de login estava incompleta; tente novamente.',
  'auth.error.tokenIncomplete':
      'A resposta do token estava incompleta; tente novamente.',
  'auth.error.ms': 'Falha no login da Microsoft: {detail}',
  'auth.error.xbox': 'Falha na autenticação do Xbox Live: {detail}',
  'auth.error.xsts': 'Falha na autorização do Xbox: {detail}',
  'auth.error.xboxRejected':
      'A autorização do Xbox foi recusada; verifique o estado da conta.',
  'auth.error.xboxNoProfile':
      'Esta conta da Microsoft ainda não tem um perfil Xbox. Entre uma vez em '
      'xbox.com e tente novamente.',
  'auth.error.xboxRegion': 'O Xbox Live não está disponível nesta região.',
  'auth.error.xboxChild':
      'Esta é uma conta infantil; adicione-a a uma família da Microsoft primeiro.',
  'auth.error.xboxCode': 'Falha na autorização do Xbox (XErr {xerr}).',
  'auth.error.whitelist':
      'A Mojang ainda não adicionou o JO-Launcher à lista de aplicativos '
      'permitidos (Invalid app registration); esta etapa não pode continuar.',
  'auth.error.minecraftRejected': 'O login do Minecraft foi recusado: {detail}',
  'auth.error.minecraft': 'Falha no login do Minecraft: {detail}',
  'auth.error.minecraftTokenIncomplete':
      'A resposta do token do Minecraft estava incompleta; tente novamente.',
  'auth.error.noJavaEdition':
      'Esta conta da Microsoft não possui o Minecraft: Java Edition.',
  'auth.error.profile': 'Não foi possível ler o perfil do jogador: {detail}',
  'auth.error.profileIncomplete':
      'O perfil do jogador estava incompleto; tente novamente.',
  'auth.error.refreshExpired': 'A sessão expirou; entre novamente.',
  'auth.error.refresh': 'Não foi possível renovar a sessão: {detail}',
  'auth.error.refreshIncomplete':
      'A resposta de renovação estava incompleta; entre novamente.',

  // Licenças
  'licenses.title': 'Licenças',
  'licenses.count': '{count} itens',
  'licenses.loading': 'Lendo a lista de licenças…',
  'licenses.viewText': 'Ver texto →',
  'licenses.unsigned': '(Sem atribuição)',
  'licenses.noText': '(Nenhum texto de licença fornecido)',

  // Erros de inicialização
  'launch.error.manifestMissing': 'Manifesto da versão não encontrado: {name}',
  'launch.error.manifestRead':
      'Não foi possível ler o manifesto da versão {name}: {error}',
  'launch.error.inheritCycle': 'Herança de versão em ciclo: {name}',
  'launch.error.javaPath': 'Não é um executável Java utilizável: {path}',
  'launch.error.noJava':
      'Nenhum runtime Java encontrado. Defina o caminho do Java nas configurações da versão.',
  'launch.error.javaTooOld':
      'Esta versão requer Java {required}, mas foi encontrado Java {found}.',
  'launch.error.missingClient': 'O jar do cliente está ausente: {path}',
  'launch.error.missingLibrary': 'Arquivo de biblioteca ausente: {path}',
  'launch.error.missingAssetsIndex':
      'O manifesto desta versão não tem índice de assets.',
  'launch.error.missingAssets': 'Índice de assets ausente: {path}',
  'launch.error.noMainClass':
      'O manifesto desta versão não tem classe principal.',
  'launch.error.natives': 'Não foi possível extrair os natives: {error}',
  'launch.error.start': 'Não foi possível iniciar o jogo: {error}',
  'launch.error.alreadyRunning': 'Esta versão já está em execução.',
  'launch.loginRequired': 'Entre para iniciar o jogo.',
  'launch.starting': 'Iniciando…',
  'launch.log': 'Log',
  'launch.stop': 'Encerrar',
  'launch.logTitle': 'Log do jogo · {name}',

  // Loaders
  'loader.vanilla': 'Vanilla',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
