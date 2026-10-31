# JO-Launcher

Minecraft: Java Edition 向けの Windows デスクトップランチャーです。Linux 対応は計画中です。

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [**日本語**](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

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
- 診断ログ（設定 → 概要 → ログ）でトラブルシューティング
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
platform/win32/       Win32 + Direct2D shell
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## ビルド（Windows）

Visual Studio 2022 または 2026 の C++ ワークロード（または対応する Build Tools）と CMake 3.25+ が必要です。

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
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
再配布時は [NOTICE](./NOTICE) を含め、そこに記載された第三者通知を保持する必要があります。プライバシー通知：[PRIVACY.md](./PRIVACY.md)。

Minecraft の公式製品ではありません。Mojang または Microsoft の承認や関連はありません。Minecraft、Mojang、Microsoft、Xbox は Microsoft Corporation またはその関連会社の商標です。
