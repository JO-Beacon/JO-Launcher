<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>Minecraft: Java Edition 向けの Windows デスクトップランチャーです。Linux 対応は計画中です。</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">公式サイト</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">最新リリース</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <b>日本語</b> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## 必要条件

- Windows 10 または 11、x64
- 起動する Minecraft バージョンに対応した Java ランタイム（自動検出。バージョンごとに手動指定も可能）
- Minecraft: Java Edition を所有する Microsoft アカウント
- サインイン用の独自の Azure アプリケーション（クライアント）ID

## 機能

- インストール済みの Minecraft バージョンを起動
- バージョンごとの設定：Java ランタイム、メモリ上限、JVM 引数
- 搭載メモリに基づく自動メモリ計画（バージョンごとに上書き可能）
- バージョンのフォルダーまたは zip をインポート、名前変更、削除
- 診断ログ（設定 → ログ）でトラブルシューティング
- バージョンごとのゲームディレクトリ：セーブ、設定、Mod は各バージョンのフォルダー内に保存され、バージョン間で分離
- デバイスコードフローで Microsoft にサインイン。設定 → アカウント で独自の Azure アプリケーション（クライアント）ID を設定するか、`JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID` 環境変数を使用
- 10 種類の UI 言語：English、简体中文、繁體中文、日本語、한국어、Deutsch、Español、Français、Português、Svenska
- ダーク、ライト、システム連動テーマ
- 実行ファイルの隣にあるポータブル `.minecraft` フォルダーを優先し、なければ `%APPDATA%\.minecraft` を使用

## ディレクトリ構成

```text
core/                 platform-independent C++20 core
  auth/               Microsoft / Xbox / Minecraft sign-in
  launch/             version manifests, Java detection, process launch
  mc/                 version scanning and per-version settings
  net/                HTTP transport
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## ビルド（Windows）

Visual Studio 2022 または 2026 の C++ ワークロード（または対応する Build Tools）、CMake 3.25+、Pillow 入りの Python 3 が必要です。アイコンはバージョン管理に含めていないため、ビルド前に `python tools/export-icons.py` を実行してください（ヘッドレス Edge または Chrome で SVG から各サイズを生成します）。

オプション（実験的）: [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) をリポジトリと同じ階層にチェックアウトし、構成時に `-DJO_USE_DRAFTUI=ON` を渡すと有効になります。既定では無効で、無くてもビルドできます。画面はいまも手書きの Direct2D 描画が基準です。

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

出力：

```text
build/native/Release/JO-Launcher.exe
```

実行ファイルは MSVC ランタイムに静的リンクされています。

## 状態

実装済みの UI は Win32 シェルのみです。Linux の HTTP、シークレットストレージ、プロセスバックエンドは `core/platform/` にありますが、GTK シェルはまだ開始していません。

## ライセンス

JO-Launcher は Apache License 2.0 でライセンスされています。詳細は [LICENSE](./LICENSE) を参照してください。
アイコン（`assets/icon/`、`platform/win32/app.ico`、サイトのアイコン）は Apache License 2.0 の対象外で、すべての権利を留保します。一切改変しておらず公式版と同一の JO-Launcher には同梱できますが、fork・改名・バージョン番号の変更を含め、いかなる改変がある場合も差し替えが必要です。詳細は [assets/icon/LICENSE](./assets/icon/LICENSE) を参照してください。
再配布時は [NOTICE](./NOTICE) を含め、そこに記載された第三者通知を保持する必要があります。プライバシー通知：[PRIVACY.md](./PRIVACY.md)。

Minecraft の公式製品ではありません。Mojang または Microsoft の承認や関連はありません。Minecraft、Mojang、Microsoft、Xbox は Microsoft Corporation またはその関連会社の商標です。
