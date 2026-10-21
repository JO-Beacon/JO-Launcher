// Japanese.

const Map<String, String> stringsJa = <String, String>{
  // Common
  'common.cancel': 'キャンセル',
  'common.close': '閉じる',
  'common.retry': '再試行',
  'common.back': '戻る',
  'common.save': '保存',
  'common.saving': '保存中…',
  'common.saved': '保存しました。',
  'common.login': 'サインイン',
  'common.logout': 'サインアウト',
  'common.delete': '削除',
  'common.change': '変更',
  'common.view': '表示',
  'common.openFolder': 'フォルダーを開く',
  'common.notYet': '未対応',
  'common.auto': '自動',
  'common.manual': '手動',
  'common.enabled': '有効',
  'common.disabled': '無効',
  'common.keyPress': 'キーの組み合わせを押してください…',
  'common.keyUnset': '未設定',
  'common.loading': '読み込み中…',
  'common.listSeparator': '、',

  // ナビゲーションとサイドバー
  'nav.launch': '起動',
  'nav.version': 'バージョン設定',
  'nav.settings': '設定',
  'rail.microsoftLogin': 'Microsoft サインイン',

  // プライバシー
  'privacy.title': 'プライバシー',
  'privacy.hint': 'ローカルアカウントデータの取り扱い',
  'privacy.summary':
      'JO-Launcher は、このデバイス上で Microsoft アカウント名、Minecraft '
      'のプレイヤー名と UUID、ログイントークン（access / refresh）、'
      'プロフィール / スキン情報を処理します。\n\n'
      'これらのデータは Windows DPAPI で保護されたローカルファイルにのみ保存され、'
      'サインイン、セッションの更新、ゲームの起動に使用されます。'
      'JO-Launcher のサーバーにはアップロードされず、テレメトリーもありません。\n\n'
      'サインイン時に、データは各社のプライバシーポリシーに基づき '
      'Microsoft / Xbox / Minecraft のサービスへ送信されます。\n\n'
      '設定 → アカウント → アカウントとローカルデータを削除 から、'
      'いつでも削除できます。',
  'privacy.agree': '同意して続行',
  'privacy.fullNotice': '完全なプライバシー通知を開く',
  'privacy.linkError': 'プライバシー通知を開けませんでした。',

  // Launch page
  'launch.title': '起動',
  'launch.subtitle': '現在のバージョンと実行中のインスタンス',
  'launch.rescan': '再スキャン',
  'launch.scanError': 'ゲームディレクトリを読み込めません：{error}',
  'launch.noVersionsDir': 'このディレクトリに versions フォルダーがありません。',
  'launch.noVersions': '起動できるバージョンがまだありません。',
  'launch.chooseVersion': '起動するバージョンを選択',
  'launch.versionCount': 'このディレクトリには {count} 個のバージョンがあります。',
  'launch.switch': '切り替え',
  'launch.collapse': '折りたたむ',
  'launch.launchGame': 'ゲームを起動',
  'launch.notImplemented': '起動機能はまだ実装されていません。',
  'launch.running': '実行中',
  'launch.noneRunning': '実行中のゲームはありません。',
  'launch.broken': '他に {count} 個のフォルダーはマニフェストを読み取れません：{names}',

  // Version settings
  'version.title': 'バージョン設定',
  'version.current': '現在のバージョン',
  'version.reload': '再読み込み',
  'version.pickFirst': '先に起動ページでバージョンを選択してください。',
  'version.goLaunch': '起動ページへ',
  'version.versionSection': 'バージョン',
  'version.name': '名前',
  'version.gameVersion': 'ゲームバージョン',
  'version.loader': 'ローダー',
  'version.directory': 'ディレクトリ',
  'version.javaSection': 'Java',
  'version.javaSource': 'ソース',
  'version.javaAutoHint': '自動 = 起動時に検出',
  'version.javaPathHint': 'java.exe / javaw.exe のフルパス',
  'version.memorySection': 'メモリ',
  'version.memoryMin': '最小',
  'version.memoryMax': '最大',
  'version.memoryHint': 'MB、空欄 = 自動',
  'version.jvmSection': 'JVM 引数',
  'version.jvmHint': '例: -XX:+UseG1GC、空欄 = なし',
  'version.errorRead': 'バージョン設定を読み込めません：{error}',
  'version.errorOpenFolder': 'フォルダーを開けません。',
  'version.errorMemoryNumber': 'メモリは正の整数で入力するか、空欄にしてください。',
  'version.errorMemoryPositive': 'メモリは 0 より大きい必要があります。',
  'version.errorMemoryOrder': '最小メモリは最大メモリを超えられません。',
  'version.errorWrite': 'jolauncher.json を書き込めません：{error}',

  // Settings
  'settings.title': '設定',
  'settings.subtitle': '外観、ディレクトリ、このアプリについて',
  'settings.sectionLanguage': '言語',
  'settings.language': '表示言語',
  'settings.languageSystem': 'システムに合わせる',
  'settings.sectionAppearance': '外観',
  'settings.dark': 'ダーク',
  'settings.light': 'ライト',
  'settings.darkHint': 'システムに合わせているため、この設定は無効です',
  'settings.followSystem': 'システムに合わせる',
  'settings.followSystemHint': 'システムの外観設定に合わせる',
  'settings.sectionGameDir': 'ゲームディレクトリ',
  'settings.currentDir': '現在のディレクトリ',
  'settings.sectionAccount': 'アカウント',
  'settings.microsoftAccount': 'Microsoft アカウント',
  'settings.loginToPlay': 'サインインするとゲームを起動できます',
  'settings.characterName': 'プレイヤー名',
  'settings.loginStatus': 'サインイン状態',
  'settings.autoRenew': 'トークンの期限が切れると自動で更新されます',
  'settings.deleteAccount': 'アカウントとローカルデータを削除',
  'settings.deleteAccountHint': 'このデバイスからアカウント、トークン、キャッシュされたプロフィールを削除します。',
  'settings.deleteAccountTitle': 'アカウントとローカルデータを削除しますか？',
  'settings.deleteAccountMessage':
      'サインイン中のアカウント、アクセストークン、リフレッシュトークン、'
      'キャッシュされたプロフィールをこのデバイスから削除します。'
      'ゲームファイルとバージョン設定は削除されません。この操作は元に戻せません。',
  'settings.deleteAccountError': 'ローカルアカウントデータを削除できませんでした：{error}',
  'settings.sectionAbout': 'このアプリについて',
  'settings.version': 'バージョン',
  'settings.licenses': 'ライセンス',
  'settings.licensesHint': 'このアプリとサードパーティコンポーネント',
  'settings.licenseName': 'Apache License 2.0',
  'settings.disclaimer':
      'MINECRAFT の公式製品ではありません。MOJANG または MICROSOFT の承認を'
      '受けておらず、両社とも提携していません。',
  'settings.versionReadError': '読み取れません',
  'settings.pickerError': 'フォルダー選択ダイアログを開けません：{error}',

  // Microsoft サインイン
  'auth.title': 'Microsoft サインイン',
  'auth.requesting': 'サインインコードを要求しています…',
  'auth.instructions': 'ブラウザーで下のリンクを開き、コードを入力してください：',
  'auth.copyCode': 'コードをコピー',
  'auth.openLink': 'リンクを開く',
  'auth.waiting': '認証を待っています…',
  'auth.copied': 'コードをコピーしました。',
  'auth.openBrowserFailed': 'ブラウザーを開けません。リンクを手動でコピーしてください。',
  'auth.errorGeneric': 'サインインに失敗しました：{error}',
  'auth.error.noClientId':
      'このビルドには Microsoft の client_id が設定されていないため、'
      'サインインできません。環境変数 JO_MS_CLIENT_ID を設定するか、'
      'ビルド時に --dart-define=JO_MS_CLIENT_ID=... を渡してください。',
  'auth.error.timeout': 'サインインがタイムアウトしました。もう一度お試しください。',
  'auth.error.declined': '認証ページでサインインを拒否しました。',
  'auth.error.codeExpired': 'サインインコードの有効期限が切れました。もう一度お試しください。',
  'auth.error.codeInvalid': 'サインインコードが無効です。もう一度お試しください。',
  'auth.error.deviceCode': 'サインインコードを要求できません：{detail}',
  'auth.error.deviceCodeIncomplete': 'サインインコードの応答が不完全です。もう一度お試しください。',
  'auth.error.tokenIncomplete': 'トークンの応答が不完全です。もう一度お試しください。',
  'auth.error.ms': 'Microsoft サインインに失敗しました：{detail}',
  'auth.error.xbox': 'Xbox Live の認証に失敗しました：{detail}',
  'auth.error.xsts': 'Xbox の認証に失敗しました：{detail}',
  'auth.error.xboxRejected': 'Xbox の認証が拒否されました。アカウントの状態を確認してください。',
  'auth.error.xboxNoProfile':
      'この Microsoft アカウントにはまだ Xbox プロフィールがありません。'
      'xbox.com で一度サインインしてから再試行してください。',
  'auth.error.xboxRegion': 'お住まいの地域では Xbox Live を利用できません。',
  'auth.error.xboxChild': '未成年のアカウントです。先に Microsoft ファミリーに追加してください。',
  'auth.error.xboxCode': 'Xbox の認証に失敗しました（XErr {xerr}）。',
  'auth.error.whitelist':
      'Mojang はまだ JO-Launcher をアプリケーション許可リストに追加していません'
      '（Invalid app registration）。この手順は進められません。',
  'auth.error.minecraftRejected': 'Minecraft のサインインが拒否されました：{detail}',
  'auth.error.minecraft': 'Minecraft のサインインに失敗しました：{detail}',
  'auth.error.minecraftTokenIncomplete': 'Minecraft トークンの応答が不完全です。もう一度お試しください。',
  'auth.error.noJavaEdition':
      'この Microsoft アカウントは Minecraft: Java Edition を所有していません。',
  'auth.error.profile': 'プレイヤープロフィールを読み取れません：{detail}',
  'auth.error.profileIncomplete': 'プレイヤープロフィールが不完全です。もう一度お試しください。',
  'auth.error.refreshExpired': 'セッションの有効期限が切れました。もう一度サインインしてください。',
  'auth.error.refresh': 'セッションを更新できません：{detail}',
  'auth.error.refreshIncomplete': '更新の応答が不完全です。もう一度サインインしてください。',

  // ライセンス
  'licenses.title': 'ライセンス',
  'licenses.count': '全 {count} 件',
  'licenses.loading': 'ライセンス一覧を読み込んでいます…',
  'licenses.viewText': '本文を見る →',
  'licenses.unsigned': '(未署名)',
  'licenses.noText': '（この項目にはライセンス本文がありません）',

  // Launch errors
  'launch.error.manifestMissing': 'バージョンマニフェストが見つかりません：{name}',
  'launch.error.manifestRead': '{name} のバージョンマニフェストを読み込めません：{error}',
  'launch.error.inheritCycle': 'バージョンの継承が循環しています：{name}',
  'launch.error.javaPath': '使用できる Java ではありません：{path}',
  'launch.error.noJava': 'Java ランタイムが見つかりません。バージョン設定で Java のパスを指定してください。',
  'launch.error.javaTooOld':
      'このバージョンには Java {required} が必要ですが、Java {found} が見つかりました。',
  'launch.error.missingClient': 'クライアント jar がありません：{path}',
  'launch.error.missingLibrary': 'ライブラリファイルがありません：{path}',
  'launch.error.missingAssetsIndex': 'このバージョンのマニフェストにはアセットインデックスがありません。',
  'launch.error.missingAssets': 'アセットインデックスがありません：{path}',
  'launch.error.noMainClass': 'このバージョンのマニフェストにはメインクラスがありません。',
  'launch.error.natives': 'natives を展開できません：{error}',
  'launch.error.start': 'ゲームを起動できません：{error}',
  'launch.error.alreadyRunning': 'このバージョンはすでに実行中です。',
  'launch.loginRequired': 'ゲームを起動するにはサインインしてください。',
  'launch.starting': '起動中…',
  'launch.log': 'ログ',
  'launch.stop': '終了',
  'launch.logTitle': 'ゲームログ · {name}',

  // ローダー
  'loader.vanilla': 'バニラ',
  'loader.fabric': 'Fabric',
  'loader.quilt': 'Quilt',
  'loader.forge': 'Forge',
  'loader.neoforge': 'NeoForge',
};
